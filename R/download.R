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

  ok <- .infosiga_try_zip_sources(
    urls,
    destfile = tmp,
    quiet = quiet,
    fallback_action = "Trying an INFOSIGA-SP mirror at"
  )

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

# Try ZIP sources in order, leaving the first valid archive at `destfile`.
# Download errors and non-ZIP responses fall through to the next source.
.infosiga_try_zip_sources <- function(
  urls,
  destfile,
  quiet,
  first_action = NULL,
  fallback_action = "Previous source failed; trying mirror"
) {
  for (i in seq_along(urls)) {
    url <- urls[[i]]
    action <- if (i == 1L) first_action else fallback_action

    if (!quiet && !is.null(action)) {
      cli::cli_alert_info("{action} {.url {url}}")
    }

    downloaded <- tryCatch(
      {
        utils::download.file(
          url,
          destfile = destfile,
          mode = "wb",
          quiet = quiet
        )
        TRUE
      },
      error = function(error) {
        if (!quiet) {
          cli::cli_alert_warning(
            "Source {.url {url}} failed: {conditionMessage(error)}"
          )
        }
        FALSE
      }
    )

    if (isTRUE(downloaded) && .infosiga_is_zip(destfile)) {
      return(TRUE)
    }

    if (isTRUE(downloaded) && !quiet) {
      cli::cli_alert_warning(
        "Source {.url {url}} did not return a valid ZIP archive."
      )
    }

    unlink(destfile)
  }

  FALSE
}
