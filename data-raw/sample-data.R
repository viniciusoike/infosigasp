# Regenerate the bundled samples and the test fixture archive.
#
# The samples in inst/extdata/ and the fixture in tests/testthat/fixtures/ are
# small extracts of the real INFOSIGA-SP archive, kept in the package so that
# examples and tests run without a ~120 MB download.
#
# Run this script after a schema change in the upstream data. It downloads the
# real archive, takes the first rows of each member and writes the extracts.

library(infosigasp)

zip_path <- infosiga_download(overwrite = TRUE)

work <- tempfile("infosiga_raw_")
dir.create(work)
utils::unzip(zip_path, exdir = work)

datasets <- c("sinistros", "pessoas", "veiculos")
extdata <- "inst/extdata"
fixtures <- "tests/testthat/fixtures"
dir.create(extdata, recursive = TRUE, showWarnings = FALSE)
dir.create(fixtures, recursive = TRUE, showWarnings = FALSE)

fixture_dir <- tempfile("infosiga_fixture_")
dir.create(fixture_dir)

for (d in datasets) {
  members <- list.files(work, pattern = paste0("^", d, "_\\d{4}-\\d{4}\\.csv$"))

  # UTF-8 sample of the most recent period file for inst/extdata (100 rows).
  recent <- sort(members, decreasing = TRUE)[1]
  recent_lines <- readLines(file.path(work, recent), n = 101, encoding = "latin1")
  recent_utf8 <- iconv(recent_lines, from = "latin1", to = "UTF-8")
  writeLines(recent_utf8, file.path(extdata, paste0(d, "_sample.csv")))

  # Latin-1 fixtures: keep both period files so the row-bind path is tested.
  for (m in members) {
    lines <- readLines(file.path(work, m), n = 16, encoding = "latin1")
    con <- file(file.path(fixture_dir, m), encoding = "latin1")
    writeLines(lines, con)
    close(con)
  }
}

old <- setwd(fixture_dir)
utils::zip(
  file.path("..", basename(tempfile(fileext = ".zip"))),
  files = list.files()
)
setwd(old)

# The line above is illustrative; in practice the fixture is built with the
# system `zip` tool to match the upstream archive structure:
#   cd <fixture_dir> && zip dados_infosiga.zip *.csv
