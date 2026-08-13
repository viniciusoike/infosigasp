#' List the available INFOSIGA-SP datasets
#'
#' Returns a small tibble describing the datasets that [read_infosiga()] can
#' import, including their grain (what one row represents) and key columns.
#'
#' @return A [tibble][tibble::tibble] with columns `dataset`, `description`,
#'   `grain` and `keys`.
#'
#' @examples
#' infosiga_datasets()
#' @export
infosiga_datasets <- function() {
  tibble::tibble(
    dataset = c("sinistros", "pessoas", "veiculos"),
    description = c(
      "Traffic crash events recorded in the state of Sao Paulo.",
      "People (victims) involved in traffic crashes.",
      "Vehicles involved in traffic crashes."
    ),
    grain = c(
      "one row per crash event",
      "one row per person",
      "one row per vehicle"
    ),
    keys = c(
      "id_sinistro",
      "id_pessoa (id_sinistro, id_veiculo)",
      "id_veiculo (id_sinistro)"
    )
  )
}

#' Download the INFOSIGA-SP data dictionary
#'
#' Downloads the official INFOSIGA-SP data dictionary, a set of PDF documents
#' (one per dataset) describing every column and its accepted values. The
#' archive is saved to the cache and the extracted PDF paths are returned.
#'
#' @param dest Directory in which to extract the PDF files. Defaults to a
#'   `dictionary` sub-folder of [infosiga_cache_dir()].
#' @param overwrite Logical. Re-download even if the dictionary archive is
#'   already cached. Defaults to `FALSE`.
#' @param quiet Logical. Suppress progress messages. Defaults to `FALSE`.
#'
#' @return A character vector of paths to the extracted PDF files, invisibly.
#'
#' @examples
#' \dontrun{
#' pdfs <- infosiga_dictionary()
#' # Open the dictionary for the crash-events dataset
#' browseURL(grep("sinistros", pdfs, value = TRUE))
#' }
#' @export
infosiga_dictionary <- function(dest = file.path(infosiga_cache_dir(), "dictionary"),
                                overwrite = FALSE,
                                quiet = FALSE) {
  if (!dir.exists(dest)) {
    dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  }

  existing <- list.files(dest, pattern = "\\.pdf$", full.names = TRUE)
  if (length(existing) > 0 && !overwrite) {
    if (!quiet) {
      cli::cli_alert_info("Using cached data dictionary in {.path {dest}}.")
    }
    return(invisible(existing))
  }

  urls <- .infosiga_dictionary_url()

  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = max(600, old_timeout))

  tmp <- tempfile(fileext = ".zip")
  on.exit(unlink(tmp), add = TRUE)

  # Download to a tempfile and validate the archive's ZIP magic bytes before
  # extracting, mirroring infosiga_download(). A portal that serves an HTML
  # error page (with a 200 status), or an unreachable mirror, then falls through
  # to the next source instead of leaving junk in the cache directory.
  ok <- FALSE
  for (i in seq_along(urls)) {
    url <- urls[[i]]
    if (!quiet) {
      action <- if (i == 1L) {
        "Downloading data dictionary from"
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

    if (isTRUE(downloaded) && .infosiga_is_zip(tmp)) {
      ok <- TRUE
      break
    }
    if (isTRUE(downloaded) && !quiet) {
      cli::cli_alert_warning(
        "Source {.url {url}} did not return a valid ZIP archive."
      )
    }
    unlink(tmp)
  }

  if (!ok) {
    cli::cli_abort(c(
      "Failed to download the data dictionary from {length(urls)} source{?s}.",
      "i" = "Check your internet connection or try again later.",
      "i" = "You can supply a mirror with {.code options(infosigasp.dictionary_url = ...)}."
    ))
  }

  utils::unzip(tmp, exdir = dest)
  pdfs <- list.files(dest, pattern = "\\.pdf$", full.names = TRUE)
  if (!quiet) {
    cli::cli_alert_success(
      "Extracted {length(pdfs)} dictionary file{?s} to {.path {dest}}."
    )
  }
  invisible(pdfs)
}
