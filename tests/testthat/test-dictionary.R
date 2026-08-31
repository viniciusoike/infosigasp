test_that("dictionary_infosiga returns the online dictionary by default", {
  url <- dictionary_infosiga(open = FALSE)

  expect_identical(
    url,
    "https://viniciusoike.github.io/infosigasp/articles/data-dictionary.html"
  )
})

test_that("dictionary_infosiga links to a dataset section", {
  url <- dictionary_infosiga("pessoas", open = FALSE)

  expect_match(url, "articles/data-dictionary\\.html#pessoas$")
})

test_that("dictionary_infosiga can return the official source", {
  url <- dictionary_infosiga(
    "sinistros",
    source = "official",
    open = FALSE
  )

  expect_identical(url, "https://infosiga.detran.sp.gov.br/")
})

test_that("dictionary_infosiga validates its arguments", {
  expect_snapshot(dictionary_infosiga("other", open = FALSE), error = TRUE)
  expect_snapshot(
    dictionary_infosiga(source = "other", open = FALSE),
    error = TRUE
  )
  expect_snapshot(dictionary_infosiga(open = NA), error = TRUE)
})
