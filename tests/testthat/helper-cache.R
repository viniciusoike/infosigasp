# Point the cache at a temporary directory seeded with the test fixture
# archive, so tests exercise the real read path without any network access.
# Staleness is switched off because the fixture's CSVs carry the timestamp of
# the day it was built and only get older; tests that assert on the staleness
# warning use local_infosiga_aged_archive() instead.
local_infosiga_fixture <- function(env = parent.frame()) {
  tmp <- withr::local_tempdir(.local_envir = env)
  fixture <- test_path("fixtures", "dados_infosiga.zip")
  file.copy(fixture, file.path(tmp, "dados_infosiga.zip"))
  withr::local_options(
    list(infosigasp.cache_dir = tmp, infosigasp.stale_days = Inf),
    .local_envir = env
  )
  tmp
}

# Seed the cache with an archive whose CSVs carry a chosen age. The staleness
# check reads the member timestamps, and the checked-in fixture's are fixed at
# the moment it was built, so tests that assert on staleness must restamp them
# or they drift as the fixture ages. Repacking needs an external `zip`; callers
# skip without one.
local_infosiga_aged_archive <- function(data_age_days, env = parent.frame()) {
  skip_if_not(nzchar(Sys.which("zip")), "the `zip` command is not available")

  cache <- withr::local_tempdir(.local_envir = env)
  staging <- withr::local_tempdir(.local_envir = env)
  utils::unzip(test_path("fixtures", "dados_infosiga.zip"), exdir = staging)

  csvs <- list.files(staging, pattern = "\\.csv$", full.names = TRUE)
  Sys.setFileTime(csvs, Sys.time() - as.difftime(data_age_days, units = "days"))
  withr::with_dir(
    staging,
    utils::zip(file.path(cache, .infosiga_zip_name), basename(csvs), flags = "-q")
  )

  withr::local_options(list(infosigasp.cache_dir = cache), .local_envir = env)
  cache
}
