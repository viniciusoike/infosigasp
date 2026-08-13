#' Check the cached archive against the package mirror
#'
#' Reports whether the INFOSIGA-SP archive published on the package mirror is
#' newer than your cached copy. Unlike the staleness warning raised by
#' [infosiga_download()], which only measures how old the local copy is, this
#' function asks a remote source what it holds. It reads a small manifest
#' (a few hundred bytes) rather than the ~120 MB archive.
#'
#' @param quiet Logical. If `FALSE` (default), report the comparison with
#'   informative messages.
#' @param timeout Timeout in seconds for fetching the manifest.
#'
#' @return A one-row [tibble][tibble::tibble], invisibly, with columns
#'   `update_available`, `identical_to_mirror`, `local_date`, `mirror_date`,
#'   `mirror_published`, `mirror_size` and `mirror_url`. The two date columns
#'   carry the timestamp of the CSVs inside each archive, `mirror_published` is
#'   when the mirror was refreshed, and `mirror_size` is in bytes.
#'
#' @details
#' The comparison is against the mirror, not against DETRAN-SP. A GitHub
#' Actions workflow re-fetches the official archive weekly and republishes it
#' whenever its contents change, so the mirror can trail the portal by up to a
#' week. `update_available = FALSE` therefore means the mirror holds nothing
#' newer than your copy, and [infosiga_download()] may still find fresher data
#' at DETRAN-SP, which it tries first.
#'
#' Both archives are identified by the MD5 sum of the ZIP file and by the
#' timestamp its members carry. A cached copy that matches the mirror's
#' checksum is reported as identical. One that differs but is not older, as
#' happens when you download from DETRAN-SP before the weekly refresh runs, is
#' reported as no update available.
#'
#' The manifest URL can be overridden with the `infosigasp.manifest_url`
#' option, which may be a character vector of mirrors tried in order.
#'
#' @seealso [infosiga_download()] to fetch the archive, and [infosiga_cache]
#'   to manage the local copy.
#'
#' @examples
#' \dontrun{
#' infosiga_check_update()
#'
#' # Refresh only when the mirror has something newer
#' if (infosiga_check_update(quiet = TRUE)$update_available) {
#'   infosiga_download(overwrite = TRUE)
#' }
#' }
#' @export
infosiga_check_update <- function(quiet = FALSE, timeout = 60) {
  manifest <- .infosiga_fetch_manifest(timeout = timeout)

  path <- file.path(infosiga_cache_dir(), .infosiga_zip_name)
  cached <- file.exists(path)
  local_md5 <- if (cached) unname(tools::md5sum(path)) else NA_character_
  local_date <- if (cached) .infosiga_archive_date(path) else NA
  local_date <- .infosiga_as_time(local_date)

  mirror_date <- .infosiga_as_time(
    suppressWarnings(as.POSIXct(manifest[["DataDate"]], tz = "UTC"))
  )

  # A checksum match settles the question; otherwise the member timestamps say
  # which copy is the newer one. An unreadable local date means a corrupt
  # cached archive, which is worth replacing either way.
  same <- cached && identical(local_md5, manifest[["Md5"]])
  older <- is.na(local_date) ||
    (!is.na(mirror_date) && mirror_date > local_date)
  update_available <- !cached || (!same && older)

  out <- tibble::tibble(
    update_available = update_available,
    identical_to_mirror = same,
    local_date = local_date,
    mirror_date = mirror_date,
    mirror_published = .infosiga_as_time(
      suppressWarnings(as.POSIXct(manifest[["Published"]],
        format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"
      ))
    ),
    mirror_size = suppressWarnings(as.numeric(manifest[["Size"]])),
    mirror_url = manifest[[".url"]]
  )

  if (!quiet) {
    .infosiga_report_update(out, cached)
  }
  invisible(out)
}

# Reporting -----------------------------------------------------------------

# Message the outcome of a check. Split out to keep the comparison above free
# of formatting.
.infosiga_report_update <- function(out, cached) {
  mirror_on <- format(out$mirror_date, "%Y-%m-%d")
  local_on <- format(out$local_date, "%Y-%m-%d")

  if (!cached) {
    cli::cli_alert_info(
      "No cached archive; the mirror holds data dated {mirror_on}."
    )
    cli::cli_alert_info("Fetch it with {.code infosiga_download()}.")
  } else if (out$identical_to_mirror) {
    cli::cli_alert_success(
      "Your cached archive matches the mirror (data dated {mirror_on})."
    )
  } else if (out$update_available) {
    cli::cli_alert_info(
      "The mirror holds data dated {mirror_on}; yours is dated {local_on}."
    )
    cli::cli_alert_info(
      "Refresh with {.code infosiga_download(overwrite = TRUE)}."
    )
  } else {
    cli::cli_alert_success(
      "Your cached archive (data dated {local_on}) is no older than the \\
       mirror ({mirror_on})."
    )
  }
  invisible(NULL)
}

# Manifest ------------------------------------------------------------------

# Fetch the mirror manifest, trying each source in turn. Returns the fields as
# a named list, with the URL that answered under `.url`.
.infosiga_fetch_manifest <- function(timeout = 60) {
  urls <- .infosiga_manifest_url()

  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = max(timeout, old_timeout))

  tmp <- tempfile(fileext = ".dcf")
  on.exit(unlink(tmp), add = TRUE)

  for (url in urls) {
    downloaded <- tryCatch(
      {
        utils::download.file(url, destfile = tmp, mode = "wb", quiet = TRUE)
        TRUE
      },
      error = function(e) FALSE
    )
    if (isTRUE(downloaded)) {
      fields <- .infosiga_read_manifest(tmp)
      if (!is.null(fields)) {
        fields[[".url"]] <- url
        return(fields)
      }
    }
    unlink(tmp)
  }

  cli::cli_abort(c(
    "Could not read the mirror manifest from {length(urls)} source{?s}.",
    "i" = "Check your internet connection or try again later.",
    "i" = "The cached archive, if any, is still usable; only the comparison \\
           is unavailable.",
    "i" = "You can supply a mirror with \\
           {.code options(infosigasp.manifest_url = ...)}."
  ))
}

# Parse a manifest file, returning NULL for anything that is not one. A mirror
# serving an error page can yield a file that read.dcf parses without
# complaint, so the checksum field is validated rather than merely present.
.infosiga_read_manifest <- function(path) {
  fields <- tryCatch(read.dcf(path), error = function(e) NULL)
  if (is.null(fields) || nrow(fields) < 1L) {
    return(NULL)
  }
  out <- as.list(fields[1L, , drop = TRUE])
  if (!all(c("Md5", "Size", "DataDate", "Published") %in% names(out))) {
    return(NULL)
  }
  if (!grepl("^[0-9a-f]{32}$", out[["Md5"]])) {
    return(NULL)
  }
  out
}

# Coerce a possibly-NA value to POSIXct, so the returned columns keep their
# type whether or not an archive was cached and readable. ZIP timestamps carry
# no zone: the mirror writes the members' raw wall-clock reading and
# utils::unzip() reports that same reading labelled UTC, so both sides are read
# as UTC and compare as published, on any machine.
.infosiga_as_time <- function(x) {
  if (length(x) != 1L || all(is.na(x))) {
    return(as.POSIXct(NA, tz = "UTC"))
  }
  as.POSIXct(x, tz = "UTC")
}
