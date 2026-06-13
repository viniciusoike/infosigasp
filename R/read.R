#' Import an INFOSIGA-SP dataset
#'
#' Downloads (if necessary) and imports one of the three INFOSIGA-SP datasets
#' as a tidy tibble. The source archive is cached locally, so the first call
#' triggers a download and subsequent calls read from disk.
#'
#' @param dataset Which dataset to import. One of:
#'   \describe{
#'     \item{`"sinistros"`}{Crash events (one row per event).}
#'     \item{`"pessoas"`}{Victims / people involved (one row per person).}
#'     \item{`"veiculos"`}{Vehicles involved (one row per vehicle).}
#'   }
#' @param year Optional integer vector used to filter rows by year of the
#'   crash (`ano_sinistro`). If `NULL` (default), all available years are
#'   returned. For example, `year = 2020:2023`.
#' @param download_if_missing Logical. If `TRUE` (default), download the
#'   archive when it is not already cached. If `FALSE` and the archive is
#'   missing, an informative error is raised.
#' @param quiet Logical. If `FALSE` (default), report progress.
#' @param ... Additional arguments passed to [infosiga_download()] (for
#'   example `overwrite = TRUE` to force a refresh).
#'
#' @return A [tibble][tibble::tibble] with one row per record. The columns
#'   keep the original INFOSIGA-SP names (in Portuguese); see the package data
#'   dictionary via [infosiga_dictionary()]. The three datasets can be joined
#'   on `id_sinistro` (and `id_veiculo`, where present).
#'
#' @details
#' Source files are encoded in Latin-1 (ISO-8859-1), use `;` as the field
#' separator, `,` as the decimal mark and `DD/MM/YYYY` dates. `read_infosiga()`
#' handles all of these and returns UTF-8 text, `Date` columns and numeric
#' coordinates. Each dataset is distributed across two period files inside the
#' archive (2015-2021 and 2022 onward); they are read and row-bound
#' transparently.
#'
#' Empty fields are read as `NA`. Note that many categorical columns instead
#' use the literal value `"NAO DISPONIVEL"` ("not available") to flag missing
#' information; these are preserved as-is so the imported data matches the
#' source. The crash-type flag columns (`tp_sinistro_*`) hold `"S"` when the
#' flag applies and `NA` otherwise.
#'
#' @seealso [infosiga_download()], [infosiga_cache_dir()],
#'   [infosiga_dictionary()].
#'
#' @examples
#' \dontrun{
#' # Import all crash events (downloads the archive on first use)
#' sinistros <- read_infosiga("sinistros")
#'
#' # Only victims from 2022 and 2023
#' vitimas <- read_infosiga("pessoas", year = 2022:2023)
#' }
#'
#' # A bundled sample (no download required) illustrates the structure:
#' sample_path <- system.file(
#'   "extdata", "sinistros_sample.csv",
#'   package = "infosigasp"
#' )
#' if (nzchar(sample_path)) head(readr::read_delim(sample_path, ";"))
#'
#' @export
read_infosiga <- function(dataset = c("sinistros", "pessoas", "veiculos"),
                          year = NULL,
                          download_if_missing = TRUE,
                          quiet = FALSE,
                          ...) {
  dataset <- match.arg(dataset)

  if (!is.null(year)) {
    year <- suppressWarnings(as.integer(year))
    if (anyNA(year)) {
      cli::cli_abort("{.arg year} must be a vector of integer years.")
    }
  }

  zip_path <- file.path(infosiga_cache_dir(), .infosiga_zip_name)
  if (!file.exists(zip_path)) {
    if (!download_if_missing) {
      cli::cli_abort(c(
        "The INFOSIGA-SP archive is not cached.",
        "i" = "Call {.run infosigasp::infosiga_download()} first, or set {.arg download_if_missing = TRUE}."
      ))
    }
    zip_path <- infosiga_download(quiet = quiet, ...)
  }

  members <- .archive_members(zip_path, dataset)
  if (length(members) == 0) {
    cli::cli_abort(c(
      "No {.val {dataset}} files were found inside the cached archive.",
      "i" = "The archive may be corrupted; try {.code infosiga_download(overwrite = TRUE)}."
    ))
  }

  exdir <- tempfile("infosiga_")
  dir.create(exdir)
  on.exit(unlink(exdir, recursive = TRUE), add = TRUE)
  utils::unzip(zip_path, files = members, exdir = exdir)

  spec <- .infosiga_col_spec(dataset)
  locale <- readr::locale(
    encoding = "latin1",
    decimal_mark = ",",
    grouping_mark = "."
  )

  if (!quiet) {
    cli::cli_alert_info(
      "Reading {length(members)} {.val {dataset}} file{?s} from the archive."
    )
  }

  parts <- lapply(file.path(exdir, members), function(f) {
    readr::read_delim(
      f,
      delim = ";",
      col_types = spec,
      locale = locale,
      na = "",
      progress = FALSE,
      show_col_types = FALSE
    )
  })

  out <- if (length(parts) == 1) parts[[1]] else do.call(rbind, parts)

  if (!is.null(year) && "ano_sinistro" %in% names(out)) {
    out <- out[out$ano_sinistro %in% year, , drop = FALSE]
  }

  out <- tibble::as_tibble(out)

  if (!quiet) {
    cli::cli_alert_success(
      "Imported {nrow(out)} row{?s} and {ncol(out)} columns of {.val {dataset}}."
    )
  }
  out
}

# Return the archive members (CSV file names) for a dataset, matched by the
# `<dataset>_<from>-<to>.csv` naming pattern.
.archive_members <- function(zip_path, dataset) {
  listing <- utils::unzip(zip_path, list = TRUE)
  pattern <- .infosiga_members(dataset)
  grep(pattern, listing$Name, value = TRUE)
}
