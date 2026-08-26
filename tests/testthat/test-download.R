# Mirror fallback ------------------------------------------------------------

test_that(".infosiga_download falls back to a mirror when a source fails", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))

  fixture <- test_path("fixtures", "dados_infosiga.zip")
  good <- paste0("file://", normalizePath(fixture, winslash = "/"))
  bad <- "file:///infosigasp/does/not/exist.zip"
  withr::local_options(list(infosigasp.zip_url = c(bad, good)))

  path <- suppressWarnings(.infosiga_download(quiet = TRUE))
  expect_true(file.exists(path))
  expect_identical(basename(path), .infosiga_zip_name)
  # The mirror's bytes reached the cache intact.
  expect_identical(file.size(path), file.size(fixture))
})

test_that("a source that returns a non-ZIP response falls back to a mirror", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))

  # A reachable source that serves an HTML error page rather than the archive.
  not_a_zip <- file.path(tmp, "error.html")
  writeLines("<html><body>503 Service Unavailable</body></html>", not_a_zip)
  bad <- paste0("file://", normalizePath(not_a_zip, winslash = "/"))

  fixture <- test_path("fixtures", "dados_infosiga.zip")
  good <- paste0("file://", normalizePath(fixture, winslash = "/"))
  withr::local_options(list(infosigasp.zip_url = c(bad, good)))

  path <- suppressWarnings(.infosiga_download(quiet = TRUE))
  expect_true(file.exists(path))
  # The valid ZIP mirror, not the HTML page, reached the cache.
  expect_identical(file.size(path), file.size(fixture))
})

test_that(".infosiga_is_zip accepts ZIP archives and rejects other files", {
  tmp <- withr::local_tempdir()
  zip <- test_path("fixtures", "dados_infosiga.zip")
  expect_true(.infosiga_is_zip(zip))

  html <- file.path(tmp, "page.html")
  writeLines("<html></html>", html)
  expect_false(.infosiga_is_zip(html))

  expect_false(.infosiga_is_zip(file.path(tmp, "missing.zip")))
})

test_that(".infosiga_download errors when every source fails", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))
  withr::local_options(list(
    infosigasp.zip_url = c("file:///nope/a.zip", "file:///nope/b.zip")
  ))

  expect_error(
    suppressWarnings(.infosiga_download(quiet = TRUE)),
    "Failed to download"
  )
})
