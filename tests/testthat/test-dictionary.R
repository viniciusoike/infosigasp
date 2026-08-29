# dictionary_infosiga() ------------------------------------------------------

test_that("dictionary_infosiga downloads and extracts the PDF files", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))

  fixture <- test_path("fixtures", "dicionario.zip")
  url <- paste0("file://", normalizePath(fixture, winslash = "/"))
  withr::local_options(list(infosigasp.dictionary_url = url))

  pdfs <- dictionary_infosiga(quiet = TRUE)

  expect_length(pdfs, 3L)
  expect_true(all(file.exists(pdfs)))
  expect_true(all(grepl("\\.pdf$", pdfs)))
  expect_setequal(
    basename(pdfs),
    c(
      "dicionario_sinistros.pdf",
      "dicionario_pessoas.pdf",
      "dicionario_veiculos.pdf"
    )
  )
})

test_that("dictionary_infosiga reuses the cache and does not re-download", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))

  fixture <- test_path("fixtures", "dicionario.zip")
  url <- paste0("file://", normalizePath(fixture, winslash = "/"))
  withr::local_options(list(infosigasp.dictionary_url = url))

  first <- dictionary_infosiga(quiet = TRUE)

  # Point the URL at a non-existent source: a second call must not touch it,
  # because the cached PDFs already satisfy the request.
  withr::local_options(list(infosigasp.dictionary_url = "file:///nope.zip"))
  second <- expect_no_error(dictionary_infosiga(quiet = TRUE))
  expect_setequal(second, first)
})

test_that("dictionary_infosiga selects one dataset and supports refresh", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))

  fixture <- test_path("fixtures", "dicionario.zip")
  url <- paste0("file://", normalizePath(fixture, winslash = "/"))
  withr::local_options(list(infosigasp.dictionary_url = url))

  path <- dictionary_infosiga("sinistros", quiet = TRUE)
  refreshed <- dictionary_infosiga("sinistros", refresh = TRUE, quiet = TRUE)

  expect_length(path, 1L)
  expect_match(basename(path), "sinistros")
  expect_identical(refreshed, path)
})

test_that("dictionary_infosiga links to the searchable online dictionary", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))

  fixture <- test_path("fixtures", "dicionario.zip")
  url <- paste0("file://", normalizePath(fixture, winslash = "/"))
  withr::local_options(list(infosigasp.dictionary_url = url))

  expect_message(
    dictionary_infosiga("pessoas"),
    "articles/data-dictionary\\.html#pessoas"
  )
})

test_that("dictionary_infosiga errors when the download fails", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))
  withr::local_options(list(
    infosigasp.dictionary_url = "file:///nope/dict.zip"
  ))

  expect_error(
    dictionary_infosiga(quiet = TRUE),
    "Failed to download"
  )
})
