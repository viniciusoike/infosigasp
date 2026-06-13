test_that("read_infosiga imports each dataset with the expected structure", {
  local_infosiga_fixture()

  sin <- read_infosiga("sinistros", quiet = TRUE)
  expect_s3_class(sin, "tbl_df")
  expect_true(all(c("id_sinistro", "data_sinistro", "latitude") %in% names(sin)))
  expect_s3_class(sin$data_sinistro, "Date")
  expect_type(sin$latitude, "double")
  expect_type(sin$qtd_pedestre, "integer")
  # Two period files are row-bound (15 data rows each in the fixture).
  expect_equal(nrow(sin), 30L)

  peo <- read_infosiga("pessoas", quiet = TRUE)
  expect_true(all(c("id_pessoa", "gravidade_lesao", "data_obito") %in% names(peo)))
  expect_s3_class(peo$data_obito, "Date")

  veh <- read_infosiga("veiculos", quiet = TRUE)
  expect_true(all(c("id_veiculo", "marca_modelo", "tipo_veiculo") %in% names(veh)))
  expect_type(veh$ano_fab, "integer")
})

test_that("latin1 source text is decoded to UTF-8", {
  local_infosiga_fixture()
  sin <- read_infosiga("sinistros", quiet = TRUE)
  # 'dia_da_semana' contains accented weekday names (e.g. Sabado, terca).
  expect_true(all(validUTF8(stats::na.omit(sin$dia_da_semana))))
})

test_that("comma decimal marks are parsed as numeric coordinates", {
  local_infosiga_fixture()
  sin <- read_infosiga("sinistros", quiet = TRUE)
  coords <- stats::na.omit(sin$latitude)
  expect_true(length(coords) > 0)
  # Sao Paulo state latitudes are negative and roughly within [-25, -19].
  expect_true(all(coords < 0))
})

test_that("year filtering keeps only requested years", {
  local_infosiga_fixture()
  sin <- read_infosiga("sinistros", year = 2022, quiet = TRUE)
  expect_true(all(sin$ano_sinistro == 2022))
  expect_true(nrow(sin) > 0)
})

test_that("invalid arguments are rejected", {
  local_infosiga_fixture()
  expect_error(read_infosiga("foo", quiet = TRUE))
  expect_error(read_infosiga("sinistros", year = "abc", quiet = TRUE))
})

test_that("missing archive without download raises an informative error", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))
  expect_error(
    read_infosiga("sinistros", download_if_missing = FALSE, quiet = TRUE),
    "not cached"
  )
})
