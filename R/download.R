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
#' DETRAN-SP updates the archive monthly; it accumulates all records from 2015
#' onward. The download URL can be overridden with the
#' `infosigasp.zip_url` option, which may be a character vector of mirror URLs
#' tried in order until one succeeds. The default is the official DETRAN-SP
#' endpoint followed by a GitHub-release mirror that serves a point-in-time
#' snapshot when the official portal is unavailable. Override the option to add
#' your own mirror or for testing.
#'
#' DETRAN-SP overwrites the archive in place each month under the same file
#' name, so a cached copy can become stale silently. Reusing a cached archive
#' older than the `infosigasp.stale_days` option (30 days by default; set to
#' `Inf` to disable) raises a warning suggesting a refresh. The age comes from
#' the cached file's modification time.
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
    .infosiga_check_staleness(dest)
    return(invisible(dest))
  }

  urls <- .infosiga_zip_url()
  if (!quiet) {
    cli::cli_alert_info("This file is large (~120 MB) and may take a while.")
  }

  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = max(timeout, old_timeout))

  tmp <- tempfile(fileext = ".zip")
  on.exit(unlink(tmp), add = TRUE)

  # Try each source in turn, falling back to the next mirror on any failure
  # (download error, or a response that is not a valid ZIP archive) until one
  # yields a usable archive.
  ok <- FALSE
  for (i in seq_along(urls)) {
    url <- urls[[i]]
    if (!quiet) {
      action <- if (i == 1L) {
        "Downloading INFOSIGA-SP archive from"
      } else {
        "Previous source failed; trying mirror"
      }
      cli::cli_alert_info("{action} {.url {url}}")
    }

    downloaded <- tryCatch(
      {
        utils::download.file(url, destfile = tmp, mode = "wb", quiet = quiet)
        TRUE
      },
      error = function(e) {
        if (!quiet) {
          cli::cli_alert_warning(
            "Source {.url {url}} failed: {conditionMessage(e)}"
          )
        }
        FALSE
      }
    )

    # An unreachable mirror or an error page (e.g. an HTML "503" served with a
    # 200 status) downloads as a non-empty file that is not a ZIP. Validate the
    # archive's magic bytes so such responses fall through to the next mirror
    # instead of poisoning the cache.
    if (isTRUE(downloaded) && .infosiga_is_zip(tmp)) {
      ok <- TRUE
      break
    }
    if (isTRUE(downloaded) && !quiet) {
      cli::cli_alert_warning(
        "Source {.url {url}} did not return a valid ZIP archive."
      )
    }
    # Discard any partial, empty or non-ZIP file before trying the next source.
    unlink(tmp)
  }

  if (!ok) {
    cli::cli_abort(c(
      "Failed to download the INFOSIGA-SP archive from {length(urls)} source{?s}.",
      "i" = "Check your internet connection or try again later.",
      "i" = "You can supply a mirror with {.code options(infosigasp.zip_url = ...)}."
    ))
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

# Default age (in days) beyond which a cached archive is considered stale.
.infosiga_stale_days <- 30L

# Warn when a cached archive is reused that is older than the staleness
# threshold. DETRAN-SP refreshes the data monthly under the same file name, so
# the cached file's modification time is a good proxy for how old the data is.
# Set `infosigasp.stale_days` to `Inf` (or a non-positive value) to disable.
.infosiga_check_staleness <- function(path) {
  if (!file.exists(path)) {
    return(invisible(NULL))
  }
  threshold <- getOption("infosigasp.stale_days", .infosiga_stale_days)
  if (!is.numeric(threshold) || !is.finite(threshold) || threshold <= 0) {
    return(invisible(NULL))
  }

  age_days <- as.numeric(
    difftime(Sys.time(), file.mtime(path), units = "days")
  )
  if (age_days > threshold) {
    cli::cli_warn(c(
      "!" = "The cached INFOSIGA-SP archive is {round(age_days)} days old.",
      "i" = "DETRAN-SP updates the data monthly; refresh with \\
             {.code infosiga_download(overwrite = TRUE)}."
    ))
  }
  invisible(NULL)
}

# Cheap integrity check: does the file start with the ZIP local-file-header
# magic bytes "PK\3\4"? This catches the common failure of a portal returning
# an HTML error page (or a truncated/empty file) with a 200 status, without
# the cost of decompressing the ~120 MB archive.
.infosiga_is_zip <- function(path) {
  if (!file.exists(path) || file.size(path) < 4L) {
    return(FALSE)
  }
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  magic <- readBin(con, "raw", n = 4L)
  identical(magic, as.raw(c(0x50, 0x4b, 0x03, 0x04)))
}
