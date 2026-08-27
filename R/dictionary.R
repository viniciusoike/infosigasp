#' Download the INFOSIGA-SP data dictionary
#'
#' Downloads the official INFOSIGA-SP data dictionary, a set of PDF documents
#' (one per dataset) describing every column and its accepted values. The
#' archive is saved to the cache and the extracted PDF paths are returned.
#'
#' @param dataset Optional dataset whose dictionary should be returned: one of
#'   `"sinistros"`, `"pessoas"` or `"veiculos"`. If `NULL` (default), return
#'   all three dictionaries.
#' @param refresh Logical. If `TRUE`, download the dictionaries again before
#'   returning them. If `FALSE` (default), reuse the local copy when available.
#' @param quiet Logical. Suppress progress messages. Defaults to `FALSE`.
#'
#' @return A character vector of paths to the extracted PDF files, invisibly.
#'
#' @examples
#' \dontrun{
#' pdfs <- dictionary_infosiga()
#' # Open the dictionary for the crash-events dataset
#' browseURL(dictionary_infosiga("sinistros"))
#' }
#' @export
dictionary_infosiga <- function(
  dataset = NULL,
  refresh = FALSE,
  quiet = FALSE
) {
  if (!is.logical(refresh) || length(refresh) != 1L || is.na(refresh)) {
    cli::cli_abort("{.arg refresh} must be `TRUE` or `FALSE`.")
  }
  if (!is.null(dataset)) {
    dataset <- match.arg(dataset, .infosiga_datasets)
  }

  dest <- .infosiga_dictionary_dir()
  existing <- list.files(dest, pattern = "\\.pdf$", full.names = TRUE)
  if (length(existing) > 0 && !refresh) {
    if (!quiet) {
      cli::cli_alert_info(
        "Using the INFOSIGA-SP dictionaries in the local infosigasp cache."
      )
    }
    return(invisible(.infosiga_select_dictionary(existing, dataset)))
  }

  urls <- .infosiga_dictionary_url()

  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = max(600, old_timeout))

  tmp <- tempfile(fileext = ".zip")
  on.exit(unlink(tmp), add = TRUE)

  # Download to a tempfile and validate the archive's ZIP magic bytes before
  # extracting, mirroring the data-archive downloader. A portal that serves an
  # HTML error page (with a 200 status), or an unreachable mirror, then falls
  # through to the next source instead of leaving junk in the cache directory.
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

  if (!dir.exists(dest)) {
    dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  }
  utils::unzip(tmp, exdir = dest)
  pdfs <- list.files(dest, pattern = "\\.pdf$", full.names = TRUE)
  if (!quiet) {
    cli::cli_alert_success(
      "Extracted {length(pdfs)} dictionary file{?s} to {.path {dest}}."
    )
  }
  invisible(.infosiga_select_dictionary(pdfs, dataset))
}

.infosiga_select_dictionary <- function(paths, dataset) {
  if (is.null(dataset)) {
    return(paths)
  }

  selected <- grep(dataset, paths, value = TRUE, ignore.case = TRUE)
  if (length(selected) == 0L) {
    cli::cli_abort(
      "No dictionary for {.val {dataset}} was found in the downloaded files."
    )
  }
  selected
}
