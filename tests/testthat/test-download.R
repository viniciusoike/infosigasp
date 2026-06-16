# Mirror fallback ------------------------------------------------------------

test_that("infosiga_download falls back to a mirror when a source fails", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))

  fixture <- test_path("fixtures", "dados_infosiga.zip")
  good <- paste0("file://", normalizePath(fixture, winslash = "/"))
  bad <- "file:///infosigasp/does/not/exist.zip"
  withr::local_options(list(infosigasp.zip_url = c(bad, good)))

  path <- suppressWarnings(infosiga_download(quiet = TRUE))
  expect_true(file.exists(path))
  expect_identical(basename(path), .infosiga_zip_name)
  # The mirror's bytes reached the cache intact.
  expect_identical(file.size(path), file.size(fixture))
})

test_that("infosiga_download errors when every source fails", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))
  withr::local_options(list(
    infosigasp.zip_url = c("file:///nope/a.zip", "file:///nope/b.zip")
  ))

  expect_error(
    suppressWarnings(infosiga_download(quiet = TRUE)),
    "Failed to download"
  )
})

# Staleness warning ----------------------------------------------------------

test_that("a stale cached archive triggers a refresh warning", {
  dir <- local_infosiga_fixture()
  archive <- file.path(dir, .infosiga_zip_name)
  # Backdate the archive well beyond the default 30-day threshold.
  Sys.setFileTime(archive, Sys.time() - as.difftime(40, units = "days"))

  expect_warning(infosiga_download(quiet = TRUE), "days old")
})

test_that("a fresh cached archive does not warn", {
  local_infosiga_fixture() # file.copy stamps the archive with the current time
  expect_no_warning(infosiga_download(quiet = TRUE))
})

test_that("staleness checking can be disabled via option", {
  dir <- local_infosiga_fixture()
  archive <- file.path(dir, .infosiga_zip_name)
  Sys.setFileTime(archive, Sys.time() - as.difftime(40, units = "days"))
  withr::local_options(list(infosigasp.stale_days = Inf))

  expect_no_warning(infosiga_download(quiet = TRUE))
})

test_that("read_infosiga warns on a stale cache but not on a fresh one", {
  dir <- local_infosiga_fixture()
  archive <- file.path(dir, .infosiga_zip_name)

  expect_no_warning(read_infosiga("sinistros", quiet = TRUE))

  Sys.setFileTime(archive, Sys.time() - as.difftime(40, units = "days"))
  expect_warning(read_infosiga("sinistros", quiet = TRUE), "days old")
})
