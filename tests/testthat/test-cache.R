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
  expect_identical(.infosiga_processed_dir(), file.path(tmp, "processed"))
})

test_that("clean reads create and reuse one canonical processed artifact", {
  local_infosiga_fixture()

  first <- read_infosiga("sinistros", quiet = TRUE)
  files <- list.files(.infosiga_processed_dir(), full.names = TRUE)

  expect_length(files, 1L)
  expect_match(basename(files), "^sinistros-clean-v[0-9]+-[a-f0-9]+\\.rds$")

  modified <- file.info(files)$mtime
  second <- read_infosiga("sinistros", quiet = TRUE)

  expect_identical(second, first)
  expect_identical(file.info(files)$mtime, modified)
})

test_that("cache false never creates a processed artifact", {
  local_infosiga_fixture()

  read_infosiga("sinistros", cache = FALSE, quiet = TRUE)

  expect_false(dir.exists(.infosiga_processed_dir()))
})

test_that("standardisation reuses rather than duplicates the clean cache", {
  local_infosiga_fixture()

  clean <- read_infosiga("veiculos", quiet = TRUE)
  standardised <- read_infosiga(
    "veiculos",
    standardize = "cores",
    quiet = TRUE
  )

  files <- list.files(.infosiga_processed_dir(), full.names = TRUE)
  expect_length(files, 1L)
  expect_identical(
    standardised,
    .infosiga_standardize(clean, "veiculos", "cores")
  )
})

test_that("corrupt processed artifacts are replaced from the source", {
  local_infosiga_fixture()

  expected <- read_infosiga("pessoas", quiet = TRUE)
  path <- list.files(.infosiga_processed_dir(), full.names = TRUE)
  writeLines("not an RDS file", path)

  actual <- read_infosiga("pessoas", quiet = TRUE)

  expect_identical(actual, expected)
  expect_no_error(readRDS(path))
})

test_that("stale processed artifacts are pruned across datasets", {
  local_infosiga_fixture()
  directory <- .infosiga_processed_dir()
  dir.create(directory)
  stale <- file.path(
    directory,
    c(
      "sinistros-clean-v0-deadbeef.rds",
      "pessoas-clean-v1-deadbeef.rds"
    )
  )
  file.create(stale)

  read_infosiga("veiculos", quiet = TRUE)

  expect_false(any(file.exists(stale)))
  expect_length(list.files(directory), 1L)
})

test_that("cache information and clearing stay within the package cache", {
  tmp <- local_infosiga_fixture()
  unrelated <- file.path(tmp, "keep-me.txt")
  writeLines("user file", unrelated)

  read_infosiga("sinistros", quiet = TRUE)
  info <- infosiga_cache_info()

  expect_named(info, c("type", "dataset", "path", "size_mb", "modified"))
  expect_setequal(info$type, c("source", "processed"))

  clear_infosiga_cache(quiet = TRUE)

  expect_false(dir.exists(.infosiga_processed_dir()))
  expect_true(file.exists(.infosiga_archive_path()))
  expect_true(file.exists(unrelated))
})

test_that("cache clearing validates its controls", {
  expect_snapshot(clear_infosiga_cache(processed = NA), error = TRUE)
})
