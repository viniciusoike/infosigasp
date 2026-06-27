test_that("clean = TRUE produces ordered factors with the correct order", {
  local_infosiga_fixture()

  sin <- read_infosiga("sinistros", quiet = TRUE)
  expect_s3_class(sin$dia_da_semana, "ordered")
  expect_identical(
    levels(sin$dia_da_semana),
    c("Domingo", "Segunda-feira",
      paste0("Ter", intToUtf8(0x00e7), "a-feira"),
      "Quarta-feira", "Quinta-feira", "Sexta-feira",
      paste0("S", intToUtf8(0x00e1), "bado"))
  )
  expect_s3_class(sin$turno, "ordered")
  expect_true(all(levels(sin$turno) == c("MADRUGADA", "MANHA", "TARDE", "NOITE")))

  peo <- read_infosiga("pessoas", quiet = TRUE)
  expect_s3_class(peo$gravidade_lesao, "ordered")
  expect_identical(levels(peo$gravidade_lesao), c("LEVE", "GRAVE", "FATAL"))
  expect_s3_class(peo$faixa_etaria_legal, "ordered")
})

test_that("ordering is semantically meaningful, not alphabetical", {
  local_infosiga_fixture()
  peo <- read_infosiga("pessoas", quiet = TRUE)
  expect_true(min(peo$gravidade_lesao, na.rm = TRUE) == "LEVE")
  expect_true(max(peo$gravidade_lesao, na.rm = TRUE) == "FATAL")
})

test_that("clean = TRUE maps the 'NAO DISPONIVEL' marker to NA", {
  local_infosiga_fixture()
  clean <- read_infosiga("pessoas", quiet = TRUE)
  raw <- read_infosiga("pessoas", clean = FALSE, quiet = TRUE)

  # The raw fixture contains the marker; the cleaned version must not.
  expect_true(any(raw$gravidade_lesao == "NAO DISPONIVEL"))
  expect_false(any(stats::na.omit(as.character(clean$tipo_de_vitima)) == "NAO DISPONIVEL"))
})

test_that("clean = FALSE returns raw character columns", {
  local_infosiga_fixture()
  raw <- read_infosiga("sinistros", clean = FALSE, quiet = TRUE)
  expect_type(raw$dia_da_semana, "character")
  expect_type(raw$turno, "character")
  expect_type(raw$ano_mes_sinistro, "character")
  expect_type(raw$tp_sinistro_atropelamento, "character")
})

test_that("clean trims whitespace and catches space-padded markers", {
  raw <- tibble::tibble(
    nacionalidade  = c("BRASILEIRA          ", "  HAITIANA", NA),
    tipo_de_vitima = c("NAO DISPONIVEL   ", "PEDESTRE", "  NAO DISPONIVEL")
  )
  cleaned <- clean_infosiga(raw, "pessoas")
  expect_identical(cleaned$nacionalidade, c("BRASILEIRA", "HAITIANA", NA))
  # A space-padded marker must still map to NA.
  expect_identical(cleaned$tipo_de_vitima, c(NA, "PEDESTRE", NA))
})

test_that("clean converts tp_sinistro_* flags to logical, keeping primario", {
  local_infosiga_fixture()
  sin <- read_infosiga("sinistros", quiet = TRUE)
  expect_type(sin$tp_sinistro_atropelamento, "logical")
  expect_type(sin$tp_sinistro_nao_disponivel, "logical")
  expect_false(anyNA(sin$tp_sinistro_atropelamento))
  # The primary-type column is categorical, not a flag.
  expect_type(sin$tp_sinistro_primario, "character")

  raw <- tibble::tibble(
    tp_sinistro_primario     = c("COLISAO", "CHOQUE"),
    tp_sinistro_atropelamento = c("S", NA),
    tp_sinistro_choque        = c(NA, "S")
  )
  cleaned <- clean_infosiga(raw, "sinistros")
  expect_identical(cleaned$tp_sinistro_atropelamento, c(TRUE, FALSE))
  expect_identical(cleaned$tp_sinistro_choque, c(FALSE, TRUE))
  expect_identical(cleaned$tp_sinistro_primario, c("COLISAO", "CHOQUE"))
})

test_that("clean fills blank counts with 0 only within a populated block", {
  raw <- tibble::tibble(
    # Row 1: vehicle block populated, gravity block fully blank.
    # Row 2: gravity block populated, vehicle block fully blank.
    # Row 3: both blocks fully blank (no breakdown recorded).
    qtd_automovel       = c(2L, NA, NA),
    qtd_motocicleta     = c(NA, NA, NA),
    qtd_gravidade_leve  = c(NA, 1L, NA),
    qtd_gravidade_fatal = c(NA, NA, NA)
  )
  cleaned <- clean_infosiga(raw, "sinistros")

  # Row 1: vehicle block has a value -> its blanks become 0; gravity block is
  # entirely blank -> left NA (genuinely not recorded).
  expect_identical(cleaned$qtd_automovel,       c(2L, NA, NA))
  expect_identical(cleaned$qtd_motocicleta,     c(0L, NA, NA))
  # Row 2: gravity block has a value -> its blanks become 0; vehicle block NA.
  expect_identical(cleaned$qtd_gravidade_leve,  c(NA, 1L, NA))
  expect_identical(cleaned$qtd_gravidade_fatal, c(NA, 0L, NA))
})

test_that("count-block filling is idempotent", {
  raw <- tibble::tibble(
    qtd_automovel      = c(2L, NA),
    qtd_motocicleta    = c(NA, NA),
    qtd_gravidade_leve = c(NA, NA)
  )
  once  <- clean_infosiga(raw, "sinistros")
  twice <- clean_infosiga(once, "sinistros")
  expect_identical(once, twice)
})

test_that("clean converts tempo_sinistro_obito to integer", {
  local_infosiga_fixture()
  peo <- read_infosiga("pessoas", quiet = TRUE)
  expect_type(peo$tempo_sinistro_obito, "integer")
})

test_that("clean strips the trailing '.0' artefact from house numbers", {
  raw <- tibble::tibble(
    numero_logradouro = c("193.0", "35.0", "123A", NA, "SN")
  )
  cleaned <- clean_infosiga(raw, "sinistros")
  expect_identical(
    cleaned$numero_logradouro,
    c("193", "35", "123A", NA, "SN")
  )
})

test_that("ano_mes_* strings become first-of-month Dates when cleaning", {
  raw <- tibble::tibble(
    ano_mes_sinistro = c("2022/01", "2023/12", "", NA),
    ano_mes_obito    = c("2022/03", NA, "2024/07", "")
  )
  cleaned <- clean_infosiga(raw, "pessoas")
  expect_s3_class(cleaned$ano_mes_sinistro, "Date")
  expect_s3_class(cleaned$ano_mes_obito, "Date")
  expect_equal(
    cleaned$ano_mes_sinistro,
    as.Date(c("2022-01-01", "2023-12-01", NA, NA))
  )
  expect_equal(
    cleaned$ano_mes_obito,
    as.Date(c("2022-03-01", NA, "2024-07-01", NA))
  )
})

test_that("coordinates outside the Sao Paulo bounding box are dropped", {
  raw <- tibble::tibble(
    latitude  = c(-23.5,    -234526,    0,  -23.5,  10.0),
    longitude = c(-46.6, 236392064,     0,    0.0, 10.0),
    descricao = c("valid SP", "corrupt", "null island",
                  "half-valid", "outside SP")
  )
  cleaned <- clean_infosiga(raw, "sinistros")
  # Only the genuine Sao Paulo point survives; everything else -> NA in pairs.
  expect_equal(cleaned$latitude,  c(-23.5, NA, NA, NA, NA))
  expect_equal(cleaned$longitude, c(-46.6, NA, NA, NA, NA))
})

test_that("a valid coordinate paired with a bad one is dropped pairwise", {
  raw <- tibble::tibble(latitude = -23.5, longitude = 999)
  cleaned <- clean_infosiga(raw, "sinistros")
  expect_true(is.na(cleaned$latitude))
  expect_true(is.na(cleaned$longitude))
})

test_that("clean_infosiga is idempotent on already-clean data", {
  local_infosiga_fixture()
  for (d in c("sinistros", "pessoas", "veiculos")) {
    once <- read_infosiga(d, quiet = TRUE)
    twice <- clean_infosiga(once, d)
    expect_identical(once, twice, info = d)
  }
})
