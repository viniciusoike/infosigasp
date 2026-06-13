#' Manage the infosigasp on-disk cache
#'
#' INFOSIGA-SP ships its data as a single archive of roughly 120 MB
#' (uncompressed, over 700 MB). To avoid repeated downloads, infosigasp stores
#' the archive in a per-user cache directory and reuses it across sessions.
#' These functions inspect and manage that cache.
#'
#' @details
#' The cache location defaults to the operating-system specific user cache
#' directory returned by [tools::R_user_dir()] (`"infosigasp"`, `"cache"`).
#' You can override it for the current session with the `infosigasp.cache_dir`
#' option, e.g. `options(infosigasp.cache_dir = "~/my-cache")`, or permanently
#' through your `.Rprofile`.
#'
#' @return
#' * `infosiga_cache_dir()` returns the cache directory path (a string),
#'   creating it if necessary.
#' * `infosiga_cache_list()` returns a character vector of cached file paths
#'   (possibly empty).
#' * `infosiga_cache_clear()` invisibly returns the paths it removed.
#'
#' @examples
#' # Where does infosigasp cache its files?
#' infosiga_cache_dir()
#'
#' # What is currently cached?
#' infosiga_cache_list()
#'
#' @name infosiga_cache
NULL

#' @rdname infosiga_cache
#' @export
infosiga_cache_dir <- function() {
  dir <- getOption(
    "infosigasp.cache_dir",
    tools::R_user_dir("infosigasp", which = "cache")
  )
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  dir
}

#' @rdname infosiga_cache
#' @export
infosiga_cache_list <- function() {
  dir <- infosiga_cache_dir()
  list.files(dir, full.names = TRUE)
}

#' @rdname infosiga_cache
#' @param confirm Logical. If `TRUE` (the default in interactive sessions),
#'   ask for confirmation before deleting cached files. Set to `FALSE` to
#'   delete without prompting (e.g. in scripts).
#' @export
infosiga_cache_clear <- function(confirm = interactive()) {
  files <- infosiga_cache_list()
  if (length(files) == 0) {
    cli::cli_alert_info("The infosigasp cache is already empty.")
    return(invisible(character(0)))
  }

  if (isTRUE(confirm)) {
    cli::cli_inform(c(
      "i" = "About to delete {length(files)} file{?s} from the cache:",
      stats::setNames(basename(files), rep("*", length(files)))
    ))
    answer <- utils::askYesNo("Delete these files?", default = FALSE)
    if (!isTRUE(answer)) {
      cli::cli_alert_info("Cache not cleared.")
      return(invisible(character(0)))
    }
  }

  unlink(files, recursive = TRUE, force = TRUE)
  cli::cli_alert_success("Removed {length(files)} file{?s} from the cache.")
  invisible(files)
}
