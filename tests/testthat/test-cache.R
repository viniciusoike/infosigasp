test_that(".infosiga_cache_dir is a pure accessor with no side effects", {
  tmp <- file.path(withr::local_tempdir(), "nested", "cache")
  withr::local_options(list(infosigasp.cache_dir = tmp))
  expect_identical(.infosiga_cache_dir(), tmp)
  # Merely querying the location must not touch the filesystem (CRAN policy).
  expect_false(dir.exists(tmp))
})

test_that(".infosiga_ensure_cache_dir creates the directory on demand", {
  tmp <- file.path(withr::local_tempdir(), "nested", "cache")
  withr::local_options(list(infosigasp.cache_dir = tmp))
  expect_identical(.infosiga_ensure_cache_dir(), tmp)
  expect_true(dir.exists(tmp))
})

test_that("cache paths are package-managed and predictable", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))
  expect_identical(.infosiga_archive_path(), file.path(tmp, .infosiga_zip_name))
  expect_identical(.infosiga_dictionary_dir(), file.path(tmp, "dictionary"))
})
