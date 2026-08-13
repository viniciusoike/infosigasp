# Manifest fixtures ----------------------------------------------------------

# Write a manifest describing `archive`, optionally overriding fields to
# describe a different (newer, or simply other) archive than the local one.
local_infosiga_manifest <- function(archive, ..., env = parent.frame()) {
  fields <- list(
    Archive = basename(archive),
    Size = format(file.size(archive), scientific = FALSE),
    Md5 = unname(tools::md5sum(archive)),
    Sha256 = strrep("0", 64),
    DataDate = format(.infosiga_archive_date(archive), "%Y-%m-%d %H:%M"),
    Published = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    Source = "https://example.invalid/dados_infosiga.zip"
  )
  fields <- utils::modifyList(fields, list(...))

  path <- file.path(withr::local_tempdir(.local_envir = env), "manifest.dcf")
  writeLines(paste0(names(fields), ": ", unlist(fields)), path)
  paste0("file://", normalizePath(path, winslash = "/"))
}

# Path of the fixture archive as seeded into the cache by the helpers.
cached_archive <- function() {
  file.path(infosiga_cache_dir(), .infosiga_zip_name)
}

# Comparison -----------------------------------------------------------------

test_that("a cache matching the mirror reports no update", {
  local_infosiga_fixture()
  url <- local_infosiga_manifest(cached_archive())
  withr::local_options(list(infosigasp.manifest_url = url))

  out <- infosiga_check_update(quiet = TRUE)
  expect_false(out$update_available)
  expect_true(out$identical_to_mirror)
  expect_equal(out$local_date, out$mirror_date)
})

test_that("a newer archive on the mirror reports an update", {
  local_infosiga_fixture()
  newer <- .infosiga_archive_date(cached_archive()) + as.difftime(30, units = "days")
  url <- local_infosiga_manifest(
    cached_archive(),
    Md5 = strrep("a", 32),
    DataDate = format(newer, "%Y-%m-%d %H:%M")
  )
  withr::local_options(list(infosigasp.manifest_url = url))

  out <- infosiga_check_update(quiet = TRUE)
  expect_true(out$update_available)
  expect_false(out$identical_to_mirror)
  expect_equal(format(out$mirror_date, "%Y-%m-%d"), format(newer, "%Y-%m-%d"))
})

test_that("a cache newer than the mirror reports no update", {
  local_infosiga_fixture()
  older <- .infosiga_archive_date(cached_archive()) - as.difftime(30, units = "days")
  url <- local_infosiga_manifest(
    cached_archive(),
    Md5 = strrep("a", 32),
    DataDate = format(older, "%Y-%m-%d %H:%M")
  )
  withr::local_options(list(infosigasp.manifest_url = url))

  out <- infosiga_check_update(quiet = TRUE)
  expect_false(out$update_available)
  expect_false(out$identical_to_mirror)
})

test_that("an empty cache reports an update and keeps the column types", {
  fixture <- test_path("fixtures", "dados_infosiga.zip")
  url <- local_infosiga_manifest(fixture)
  withr::local_options(list(
    infosigasp.cache_dir = withr::local_tempdir(),
    infosigasp.manifest_url = url
  ))

  out <- infosiga_check_update(quiet = TRUE)
  expect_true(out$update_available)
  expect_false(out$identical_to_mirror)
  expect_true(is.na(out$local_date))
  expect_s3_class(out$local_date, "POSIXct")
  expect_identical(out$mirror_size, as.numeric(file.size(fixture)))
})

test_that("the reported comparison names both dates", {
  local_infosiga_fixture()
  url <- local_infosiga_manifest(cached_archive())
  withr::local_options(list(infosigasp.manifest_url = url))

  expect_message(infosiga_check_update(), "matches the mirror")
})

# Manifest sources -----------------------------------------------------------

test_that("a source that does not serve a manifest falls back to a mirror", {
  local_infosiga_fixture()

  # A reachable source serving an error page rather than the manifest.
  not_a_manifest <- file.path(withr::local_tempdir(), "error.html")
  writeLines("<html><body>503 Service Unavailable</body></html>", not_a_manifest)
  bad <- paste0("file://", normalizePath(not_a_manifest, winslash = "/"))
  good <- local_infosiga_manifest(cached_archive())
  withr::local_options(list(infosigasp.manifest_url = c(bad, good)))

  out <- infosiga_check_update(quiet = TRUE)
  expect_true(out$identical_to_mirror)
  expect_identical(out$mirror_url, good)
})

test_that("a manifest without a valid checksum is rejected", {
  local_infosiga_fixture()
  bad <- local_infosiga_manifest(cached_archive(), Md5 = "not-a-checksum")
  withr::local_options(list(infosigasp.manifest_url = bad))

  expect_error(infosiga_check_update(quiet = TRUE), "Could not read")
})

test_that("infosiga_check_update errors when every source fails", {
  local_infosiga_fixture()
  withr::local_options(list(
    infosigasp.manifest_url = c("file:///nope/a.dcf", "file:///nope/b.dcf")
  ))

  expect_error(
    suppressWarnings(infosiga_check_update(quiet = TRUE)),
    "Could not read"
  )
})
