test_that("infosiga_datasets lists the three datasets", {
  ds <- infosiga_datasets()
  expect_s3_class(ds, "tbl_df")
  expect_setequal(ds$dataset, c("sinistros", "pessoas", "veiculos"))
  expect_true(all(c("description", "grain", "keys") %in% names(ds)))
})

test_that("column specs cover the fixture columns exactly", {
  local_infosiga_fixture()
  for (d in c("sinistros", "pessoas", "veiculos")) {
    spec <- infosigasp:::.infosiga_col_spec(d)
    df <- read_infosiga(d, quiet = TRUE)
    # Every source column has an explicit spec and vice versa.
    expect_setequal(names(spec$cols), names(df))
  }
})

test_that("the documented keys uniquely identify rows", {
  local_infosiga_fixture()
  # Keys advertised by infosiga_datasets(); verified to hold across the full
  # upstream data (id_sinistro, id_pessoa and id_sinistro+id_veiculo are
  # one-per-row with no NAs). This guards the read/row-bind path offline.
  sin <- read_infosiga("sinistros", quiet = TRUE)
  expect_false(anyNA(sin$id_sinistro))
  expect_identical(anyDuplicated(sin$id_sinistro), 0L)

  peo <- read_infosiga("pessoas", quiet = TRUE)
  expect_false(anyNA(peo$id_pessoa))
  expect_identical(anyDuplicated(peo$id_pessoa), 0L)

  veh <- read_infosiga("veiculos", quiet = TRUE)
  expect_false(anyNA(veh$id_veiculo))
  expect_identical(anyDuplicated(veh[c("id_sinistro", "id_veiculo")]), 0L)
})
