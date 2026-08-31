# Cache helpers -------------------------------------------------------------

.infosiga_cache_dir <- function() {
  getOption(
    "infosigasp.cache_dir",
    tools::R_user_dir("infosigasp", which = "cache")
  )
}

.infosiga_ensure_cache_dir <- function() {
  dir <- .infosiga_cache_dir()
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  dir
}

.infosiga_archive_path <- function() {
  file.path(.infosiga_cache_dir(), .infosiga_zip_name)
}
