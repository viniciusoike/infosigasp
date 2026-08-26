# Archive download ----------------------------------------------------------

.infosiga_download <- function(refresh = FALSE, quiet = FALSE, timeout = 3600) {
  dest <- .infosiga_archive_path()

  if (file.exists(dest) && !refresh) {
    return(invisible(dest))
  }

  urls <- .infosiga_zip_url()
  if (!quiet) {
    cli::cli_alert_info("Downloading INFOSIGA-SP data (~120 MB).")
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
    if (!quiet && i > 1L) {
      cli::cli_alert_info("Trying an INFOSIGA-SP mirror at {.url {url}}.")
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
      "Downloaded INFOSIGA-SP data ({size_mb} MB)."
    )
  }
  invisible(dest)
}

# Timestamp of the CSVs inside a cached archive, or NA if the listing cannot be
# read. This dates the data itself; the file's own mtime records only when this
# machine downloaded it, and so understates the age of the data by however long
# the archive had already been published. Reading the ZIP central directory
# decompresses nothing, so this stays cheap on the ~115 MB archive.
.infosiga_archive_date <- function(path) {
  listing <- tryCatch(utils::unzip(path, list = TRUE), error = function(e) NULL)
  if (is.null(listing) || nrow(listing) == 0 || !"Date" %in% names(listing)) {
    return(NA)
  }
  built <- suppressWarnings(max(listing$Date, na.rm = TRUE))
  if (!is.finite(as.numeric(built))) NA else built
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
