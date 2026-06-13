# Point the cache at a temporary directory seeded with the test fixture
# archive, so tests exercise the real read path without any network access.
local_infosiga_fixture <- function(env = parent.frame()) {
  tmp <- withr::local_tempdir(.local_envir = env)
  fixture <- test_path("fixtures", "dados_infosiga.zip")
  file.copy(fixture, file.path(tmp, "dados_infosiga.zip"))
  withr::local_options(list(infosigasp.cache_dir = tmp), .local_envir = env)
  tmp
}
