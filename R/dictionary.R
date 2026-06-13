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

  url <- .infosiga_dictionary_url()
  if (!quiet) {
    cli::cli_alert_info("Downloading data dictionary from {.url {url}}")
  }

  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = max(600, old_timeout))

  tmp <- tempfile(fileext = ".zip")
  on.exit(unlink(tmp), add = TRUE)
  ok <- tryCatch(
    {
      utils::download.file(url, destfile = tmp, mode = "wb", quiet = quiet)
      TRUE
    },
    error = function(e) {
      cli::cli_abort(c(
        "Failed to download the data dictionary.",
        "x" = conditionMessage(e)
      ))
    }
  )

  utils::unzip(tmp, exdir = dest)
  pdfs <- list.files(dest, pattern = "\\.pdf$", full.names = TRUE)
  if (!quiet) {
    cli::cli_alert_success(
      "Extracted {length(pdfs)} dictionary file{?s} to {.path {dest}}."
    )
  }
  invisible(pdfs)
}
