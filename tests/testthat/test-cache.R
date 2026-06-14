test_that("infosiga_cache_dir is a pure accessor with no side effects", {
  tmp <- file.path(withr::local_tempdir(), "nested", "cache")
  withr::local_options(list(infosigasp.cache_dir = tmp))
  expect_identical(infosiga_cache_dir(), tmp)
  # Merely querying the location must not touch the filesystem (CRAN policy).
  expect_false(dir.exists(tmp))
})

test_that("listing a not-yet-created cache returns an empty vector", {
  tmp <- file.path(withr::local_tempdir(), "absent")
  withr::local_options(list(infosigasp.cache_dir = tmp))
  expect_false(dir.exists(tmp))
  expect_length(infosiga_cache_list(), 0L)
  expect_false(dir.exists(tmp))
})

test_that(".infosiga_ensure_cache_dir creates the directory on demand", {
  tmp <- file.path(withr::local_tempdir(), "nested", "cache")
  withr::local_options(list(infosigasp.cache_dir = tmp))
  expect_identical(.infosiga_ensure_cache_dir(), tmp)
  expect_true(dir.exists(tmp))
})

test_that("cache listing and clearing work", {
  dir <- local_infosiga_fixture()
  expect_length(infosiga_cache_list(), 1L)

  removed <- infosiga_cache_clear(confirm = FALSE)
  expect_length(removed, 1L)
  expect_length(infosiga_cache_list(), 0L)

  # Clearing an empty cache is a no-op that returns nothing.
  expect_length(infosiga_cache_clear(confirm = FALSE), 0L)
})
