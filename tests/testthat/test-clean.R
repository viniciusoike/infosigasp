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
  once <- read_infosiga("pessoas", quiet = TRUE)
  twice <- clean_infosiga(once, "pessoas")
  expect_identical(levels(once$gravidade_lesao), levels(twice$gravidade_lesao))
  expect_identical(once$gravidade_lesao, twice$gravidade_lesao)
})
