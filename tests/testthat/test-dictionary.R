# infosiga_dictionary() ------------------------------------------------------

test_that("infosiga_dictionary downloads and extracts the PDF files", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))

  fixture <- test_path("fixtures", "dicionario.zip")
  url <- paste0("file://", normalizePath(fixture, winslash = "/"))
  withr::local_options(list(infosigasp.dictionary_url = url))

  pdfs <- infosiga_dictionary(quiet = TRUE)

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

test_that("infosiga_dictionary reuses the cache and does not re-download", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))

  fixture <- test_path("fixtures", "dicionario.zip")
  url <- paste0("file://", normalizePath(fixture, winslash = "/"))
  withr::local_options(list(infosigasp.dictionary_url = url))

  first <- infosiga_dictionary(quiet = TRUE)

  # Point the URL at a non-existent source: a second call must not touch it,
  # because the cached PDFs already satisfy the request.
  withr::local_options(list(infosigasp.dictionary_url = "file:///nope.zip"))
  second <- expect_no_error(infosiga_dictionary(quiet = TRUE))
  expect_setequal(second, first)
})

test_that("infosiga_dictionary errors when the download fails", {
  tmp <- withr::local_tempdir()
  withr::local_options(list(infosigasp.cache_dir = tmp))
  withr::local_options(list(infosigasp.dictionary_url = "file:///nope/dict.zip"))

  expect_error(
    infosiga_dictionary(quiet = TRUE),
    "Failed to download"
  )
})
