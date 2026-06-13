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
