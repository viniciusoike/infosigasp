test_that("read_infosiga imports each dataset with the expected structure", {
  local_infosiga_fixture()

  sin <- read_infosiga("sinistros", quiet = TRUE)
  expect_s3_class(sin, "tbl_df")
  expect_true(all(
    c("id_sinistro", "data_sinistro", "latitude") %in% names(sin)
  ))
  expect_s3_class(sin$data_sinistro, "Date")
  expect_type(sin$latitude, "double")
  expect_type(sin$qtd_pedestre, "integer")
  # Two period files are row-bound (15 data rows each in the fixture).
  expect_equal(nrow(sin), 30L)

  peo <- read_infosiga("pessoas", quiet = TRUE)
  expect_true(all(
    c("id_pessoa", "gravidade_lesao", "data_obito") %in% names(peo)
  ))
  expect_s3_class(peo$data_obito, "Date")

  veh <- read_infosiga("veiculos", quiet = TRUE)
  expect_true(all(
    c("id_veiculo", "marca_modelo", "tipo_veiculo") %in% names(veh)
  ))
  expect_type(veh$ano_fab, "integer")
})

test_that("latin1 source text is decoded to UTF-8", {
  local_infosiga_fixture()
  sin <- read_infosiga("sinistros", processing = "raw", quiet = TRUE)
  # 'dia_da_semana' contains accented weekday names (e.g. Sabado, terca).
  expect_true(all(validUTF8(stats::na.omit(sin$dia_da_semana))))
})

test_that("comma decimal marks are parsed as numeric coordinates", {
  local_infosiga_fixture()
  sin <- read_infosiga("sinistros", processing = "typed", quiet = TRUE)
  coords <- stats::na.omit(sin$latitude)
  expect_true(length(coords) > 0)
  # Sao Paulo state latitudes are negative and roughly within [-25, -19].
  expect_true(all(coords < 0))
})

test_that("invalid arguments are rejected", {
  local_infosiga_fixture()
  expect_snapshot(read_infosiga("foo", quiet = TRUE), error = TRUE)
  expect_snapshot(
    read_infosiga("sinistros", processing = "other", quiet = TRUE),
    error = TRUE
  )
  expect_snapshot(
    read_infosiga("sinistros", refresh = NA, quiet = TRUE),
    error = TRUE
  )
  expect_snapshot(
    read_infosiga(
      "sinistros",
      processing = "typed",
      standardize = "municipios",
      quiet = TRUE
    ),
    error = TRUE
  )
})

test_that("processing modes form a raw, typed, clean hierarchy", {
  local_infosiga_fixture()

  raw <- read_infosiga("sinistros", processing = "raw", quiet = TRUE)
  typed <- read_infosiga("sinistros", processing = "typed", quiet = TRUE)
  clean <- read_infosiga("sinistros", processing = "clean", quiet = TRUE)

  expect_identical(dim(raw), dim(typed))
  expect_identical(dim(typed), dim(clean))
  expect_identical(all(vapply(raw, is.character, logical(1))), TRUE)
  expect_type(raw$data_sinistro, "character")
  expect_s3_class(typed$data_sinistro, "Date")
  expect_s3_class(clean$data_sinistro, "Date")
  expect_type(typed$tp_sinistro_atropelamento, "character")
  expect_type(clean$tp_sinistro_atropelamento, "logical")
  expect_type(typed$dia_da_semana, "character")
  expect_s3_class(clean$dia_da_semana, "ordered")
  expect_gt(sum(raw == "", na.rm = TRUE), 0)
  expect_equal(sum(typed == "", na.rm = TRUE), 0)
  expect_s3_class(attr(raw, "problems"), "tbl_df")
  expect_s3_class(attr(typed, "problems"), "tbl_df")
  expect_s3_class(attr(clean, "problems"), "tbl_df")
})

test_that("typed processing parses classes but does not clean source labels", {
  local_infosiga_fixture()

  typed <- read_infosiga("pessoas", processing = "typed", quiet = TRUE)
  clean <- read_infosiga("pessoas", processing = "clean", quiet = TRUE)

  expect_s3_class(typed$data_sinistro, "Date")
  expect_type(typed$gravidade_lesao, "character")
  expect_s3_class(clean$gravidade_lesao, "ordered")
  expect_identical(any(grepl(" $", typed$nacionalidade)), TRUE)
  expect_identical(any(grepl(" $", clean$nacionalidade)), FALSE)
  expect_identical(any(typed$gravidade_lesao == "NAO DISPONIVEL"), TRUE)
  expect_identical(
    any(
      stats::na.omit(as.character(clean$gravidade_lesao)) == "NAO DISPONIVEL"
    ),
    FALSE
  )
})

test_that("refresh = TRUE is forwarded to .infosiga_download on a cache hit", {
  local_infosiga_fixture()
  # Point downloads at a source that does not exist: with refresh = TRUE,
  # read_infosiga() must attempt a refresh even when a cached archive exists.
  withr::local_options(list(infosigasp.zip_url = "file:///nope/refresh.zip"))
  expect_error(
    suppressWarnings(read_infosiga("sinistros", refresh = TRUE, quiet = TRUE)),
    "Failed to download"
  )
})

test_that("a cache hit without refresh does not attempt a download", {
  local_infosiga_fixture()
  # A broken source must never be touched when a valid cached archive exists.
  withr::local_options(list(infosigasp.zip_url = "file:///nope/refresh.zip"))
  expect_no_error(read_infosiga("sinistros", quiet = TRUE))
})

test_that("a missing archive is downloaded automatically", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))
  fixture <- test_path("fixtures", "dados_infosiga.zip")
  url <- paste0("file://", normalizePath(fixture, winslash = "/"))
  withr::local_options(list(infosigasp.zip_url = url))

  out <- read_infosiga("sinistros", quiet = TRUE)
  expect_s3_class(out, "tbl_df")
  expect_true(file.exists(.infosiga_archive_path()))
})

test_that("the first interactive download asks for confirmation", {
  accepted <- .infosiga_confirm_download(
    is_interactive = TRUE,
    ask = function(...) TRUE
  )
  expect_true(accepted)

  expect_snapshot(
    .infosiga_confirm_download(
      is_interactive = TRUE,
      ask = function(...) FALSE
    ),
    error = TRUE
  )
})

test_that("standardisations can be applied through read_infosiga", {
  local_infosiga_fixture()
  source <- read_infosiga("veiculos", quiet = TRUE)
  standardised <- read_infosiga(
    "veiculos",
    standardize = "cores",
    quiet = TRUE
  )

  expect_identical(nrow(standardised), nrow(source))
  expect_identical(
    standardised,
    .infosiga_standardize(source, "veiculos", "cores")
  )
})
