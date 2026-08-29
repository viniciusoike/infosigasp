test_that("clean processing produces ordered factors with the correct order", {
  local_infosiga_fixture()

  sin <- read_infosiga("sinistros", quiet = TRUE)
  expect_s3_class(sin$dia_da_semana, "ordered")
  expect_identical(
    levels(sin$dia_da_semana),
    c(
      "Domingo",
      "Segunda-feira",
      paste0("Ter", intToUtf8(0x00e7), "a-feira"),
      "Quarta-feira",
      "Quinta-feira",
      "Sexta-feira",
      paste0("S", intToUtf8(0x00e1), "bado")
    )
  )
  expect_s3_class(sin$turno, "ordered")
  expect_true(all(
    levels(sin$turno) == c("MADRUGADA", "MANHA", "TARDE", "NOITE")
  ))

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

test_that("clean processing maps the 'NAO DISPONIVEL' marker to NA", {
  local_infosiga_fixture()
  clean <- read_infosiga("pessoas", quiet = TRUE)
  raw <- read_infosiga("pessoas", processing = "raw", quiet = TRUE)

  # The raw fixture contains the marker; the cleaned version must not.
  expect_true(any(raw$gravidade_lesao == "NAO DISPONIVEL"))
  expect_false(any(
    stats::na.omit(as.character(clean$tipo_de_vitima)) == "NAO DISPONIVEL"
  ))
})

test_that("raw processing preserves source text and empty fields", {
  local_infosiga_fixture()
  raw <- read_infosiga("pessoas", processing = "raw", quiet = TRUE)

  expect_identical(all(vapply(raw, is.character, logical(1))), TRUE)
  expect_gt(sum(raw == "", na.rm = TRUE), 0)
  expect_identical(any(grepl(" $", raw$nacionalidade)), TRUE)
  expect_identical(any(raw$gravidade_lesao == "NAO DISPONIVEL"), TRUE)
})

test_that("clean trims whitespace and catches space-padded markers", {
  raw <- tibble::tibble(
    nacionalidade = c("BRASILEIRA          ", "  HAITIANA", NA),
    tipo_de_vitima = c("NAO DISPONIVEL   ", "PEDESTRE", "  NAO DISPONIVEL")
  )
  cleaned <- .infosiga_clean(raw, "pessoas")
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
    tp_sinistro_primario = c("COLISAO", "CHOQUE"),
    tp_sinistro_atropelamento = c("S", NA),
    tp_sinistro_choque = c(NA, "S")
  )
  cleaned <- .infosiga_clean(raw, "sinistros")
  expect_identical(cleaned$tp_sinistro_atropelamento, c(TRUE, FALSE))
  expect_identical(cleaned$tp_sinistro_choque, c(FALSE, TRUE))
  expect_identical(cleaned$tp_sinistro_primario, c("COLISAO", "CHOQUE"))
})

test_that("clean preserves missing counts within populated blocks", {
  raw <- tibble::tibble(
    # Row 1: vehicle block populated, gravity block fully blank.
    # Row 2: gravity block populated, vehicle block fully blank.
    # Row 3: both blocks fully blank (no breakdown recorded).
    qtd_automovel = c(2L, NA, NA),
    qtd_motocicleta = rep(NA_integer_, 3),
    qtd_gravidade_leve = c(NA, 1L, NA),
    qtd_gravidade_fatal = rep(NA_integer_, 3)
  )
  cleaned <- .infosiga_clean(raw, "sinistros")

  expect_identical(cleaned$qtd_automovel, c(2L, NA, NA))
  expect_identical(cleaned$qtd_motocicleta, c(NA_integer_, NA, NA))
  expect_identical(cleaned$qtd_gravidade_leve, c(NA, 1L, NA))
  expect_identical(cleaned$qtd_gravidade_fatal, c(NA_integer_, NA, NA))
})

test_that("clean converts tempo_sinistro_obito to integer", {
  local_infosiga_fixture()
  peo <- read_infosiga("pessoas", quiet = TRUE)
  expect_type(peo$tempo_sinistro_obito, "integer")
})

test_that("unexpected ordinal values are preserved with a warning", {
  raw <- tibble::tibble(turno = c("MANHA", "NOVO TURNO"))

  expect_snapshot(out <- .infosiga_clean(raw, "sinistros"))
  expect_identical(out$turno, raw$turno)
})

test_that("unexpected flag values are preserved with a warning", {
  raw <- tibble::tibble(tp_sinistro_choque = c("S", "VALOR NOVO", NA))

  expect_snapshot(out <- .infosiga_clean(raw, "sinistros"))
  expect_identical(out$tp_sinistro_choque, raw$tp_sinistro_choque)
})

test_that("invalid integer strings are preserved with a warning", {
  raw <- tibble::tibble(
    tempo_sinistro_obito = c("1", "1.5", "ERRO", "999999999999", NA)
  )

  expect_snapshot(out <- .infosiga_clean(raw, "pessoas"))
  expect_identical(out$tempo_sinistro_obito, raw$tempo_sinistro_obito)
})

test_that("clean strips the trailing '.0' artefact from house numbers", {
  raw <- tibble::tibble(
    numero_logradouro = c("193.0", "35.0", "123A", NA, "SN")
  )
  cleaned <- .infosiga_clean(raw, "sinistros")
  expect_identical(
    cleaned$numero_logradouro,
    c("193", "35", "123A", NA, "SN")
  )
})

test_that("clean keeps the fractional part of highway kilometre markers", {
  # On ESTRADAS E RODOVIAS this column is a kilometre marker, not a house
  # number, so a non-zero decimal is real data. Only an exactly zero fraction
  # is an export artefact.
  raw <- tibble::tibble(
    numero_logradouro = c("0.25", "12.5", "0.001", "-1.0", "230.0")
  )
  cleaned <- .infosiga_clean(raw, "sinistros")
  expect_identical(
    cleaned$numero_logradouro,
    c("0.25", "12.5", "0.001", "-1", "230")
  )
})

test_that("ano_mes_* strings become first-of-month Dates when cleaning", {
  raw <- tibble::tibble(
    ano_mes_sinistro = c("2022/01", "2023/12", "", NA),
    ano_mes_obito = c("2022/03", NA, "2024/07", "")
  )
  cleaned <- .infosiga_clean(raw, "pessoas")
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

test_that("coordinates outside the buffered Sao Paulo boundary are dropped", {
  raw <- tibble::tibble(
    latitude = c(-23.5, -25.43, -234526, 0, -23.5, 10.0),
    longitude = c(-46.6, -49.27, 236392064, 0, 0.0, 10.0),
    descricao = c(
      "valid SP",
      "inside old bbox but outside SP",
      "corrupt",
      "null island",
      "half-valid",
      "outside SP"
    )
  )
  cleaned <- .infosiga_clean(raw, "sinistros")
  # Only the genuine Sao Paulo point survives; everything else -> NA in pairs.
  expect_equal(cleaned$latitude, c(-23.5, NA, NA, NA, NA, NA))
  expect_equal(cleaned$longitude, c(-46.6, NA, NA, NA, NA, NA))
})

test_that("a valid coordinate paired with a bad one is dropped pairwise", {
  raw <- tibble::tibble(latitude = -23.5, longitude = 999)
  cleaned <- .infosiga_clean(raw, "sinistros")
  expect_true(is.na(cleaned$latitude))
  expect_true(is.na(cleaned$longitude))
})

test_that(".infosiga_clean is idempotent on already-clean data", {
  local_infosiga_fixture()
  for (d in c("sinistros", "pessoas", "veiculos")) {
    once <- read_infosiga(d, quiet = TRUE)
    twice <- .infosiga_clean(once, d)
    expect_identical(once, twice, info = d)
  }
})
