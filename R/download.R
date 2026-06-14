#' Download the INFOSIGA-SP source archive
#'
#' Downloads the consolidated INFOSIGA-SP data archive (`dados_infosiga.zip`)
#' from DETRAN-SP into the local cache. Most users do not need to call this
#' directly: [read_infosiga()] downloads the archive on demand. Use this
#' function when you want to pre-fetch the data (for example, before going
#' offline) or to force a refresh.
#'
#' @param overwrite Logical. If `FALSE` (default) and the archive is already
#'   cached, the existing file is kept and returned. Set to `TRUE` to download
#'   again and replace it.
#' @param quiet Logical. If `FALSE` (default), report progress with
#'   informative messages.
#' @param timeout Download timeout in seconds. The archive is large (around
#'   120 MB), so the default temporarily raises [options()]`$timeout` to
#'   `3600`. Pass a larger value on slow connections.
#'
#' @return The path to the cached archive, invisibly.
#'
#' @details
#' The archive is updated monthly by DETRAN-SP and accumulates all records
#' from 2015 onward. The download URL can be overridden with the
#' `infosigasp.zip_url` option, which is mainly useful for testing.
#'
#' @seealso [read_infosiga()] to import the data, and [infosiga_cache_dir()]
#'   to locate the cache.
#'
#' @examples
#' \dontrun{
#' # Pre-fetch the archive into the cache
#' infosiga_download()
#'
#' # Force a refresh after a monthly update
#' infosiga_download(overwrite = TRUE)
#' }
#' @export
infosiga_download <- function(overwrite = FALSE,
                              quiet = FALSE,
                              timeout = 3600) {
  dest <- file.path(infosiga_cache_dir(), .infosiga_zip_name)

  if (file.exists(dest) && !overwrite) {
    if (!quiet) {
      cli::cli_alert_info(
        "Using cached archive at {.path {dest}} (use {.code overwrite = TRUE} to refresh)."
      )
    }
    return(invisible(dest))
  }

  url <- .infosiga_zip_url()
  if (!quiet) {
    cli::cli_alert_info("Downloading INFOSIGA-SP archive from {.url {url}}")
    cli::cli_alert_info("This file is large (~120 MB) and may take a while.")
  }

  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = max(timeout, old_timeout))

  tmp <- tempfile(fileext = ".zip")
  on.exit(unlink(tmp), add = TRUE)

  result <- tryCatch(
    utils::download.file(url, destfile = tmp, mode = "wb", quiet = quiet),
    error = function(e) {
      cli::cli_abort(c(
        "Failed to download the INFOSIGA-SP archive.",
        "x" = conditionMessage(e),
        "i" = "Check your internet connection or try again later."
      ))
    }
  )

  if (!file.exists(tmp) || file.size(tmp) == 0) {
    cli::cli_abort("The download produced an empty file. Please try again.")
  }

  # Move into place atomically only after a successful, non-empty download so a
  # failed refresh never corrupts an existing cached archive. The cache
  # directory is created lazily here, at the first actual write.
  .infosiga_ensure_cache_dir()
  file.copy(tmp, dest, overwrite = TRUE)

  if (!quiet) {
    size_mb <- round(file.size(dest) / 1024^2, 1)
    cli::cli_alert_success(
      "Downloaded archive ({size_mb} MB) to {.path {dest}}."
    )
  }
  invisible(dest)
}
