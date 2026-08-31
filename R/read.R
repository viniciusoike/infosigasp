#' Import an INFOSIGA-SP dataset
#'
#' Downloads (if necessary) and imports one of the three INFOSIGA-SP datasets
#' as a tidy tibble. The first interactive call asks before downloading about
#' 120 MB to the user's local cache; subsequent calls read from disk.
#'
#' @param dataset Which dataset to import.
#'   \describe{
#'     \item{`"sinistros"`}{Occurrence records: confirmed crashes and
#'       notifications (one row per record).}
#'     \item{`"pessoas"`}{Victims / people involved (one row per person).}
#'     \item{`"veiculos"`}{Vehicles involved (one row per vehicle).}
#'   }
#' @param processing Level of processing to apply. `"raw"` imports every field
#'   as character and preserves empty strings, whitespace, sentinels and source
#'   representations. `"typed"` parses the documented column classes without
#'   applying additional cleaning. `"clean"` (default) adds the package's
#'   cleaning pipeline to the typed import.
#' @param standardize Optional character vector selecting label harmonisation:
#'   `"municipios"` restores official municipality spellings and harmonises
#'   administrative-region names; `"cores"` merges duplicate vehicle-colour
#'   spellings; and `"profissoes"` applies consistent title case and missing-value
#'   markers to occupations. Use `"all"` for every option applicable to the
#'   selected dataset. Requires `processing = "clean"`.
#' @param refresh Logical. If `TRUE`, download the latest available source data
#'   before reading. If `FALSE` (default), reuse the copy in the local
#'   `infosigasp` cache, downloading it only when it is missing.
#' @param quiet Logical. If `FALSE` (default), report progress.
#'
#' @return A [tibble][tibble::tibble] with one row per record. The columns
#'   keep the original INFOSIGA-SP names (in Portuguese); see the package data
#'   dictionary via [dictionary_infosiga()]. The three datasets can be joined
#'   on `id_sinistro` (and `id_veiculo`, where present).
#'
#' @details
#' Source files are encoded in Latin-1 (ISO-8859-1), use `;` as the field
#' separator, `,` as the decimal mark and `DD/MM/YYYY` dates. Every mode
#' decodes text to UTF-8, parses the CSV structure and row-binds the period files.
#' The modes differ in what happens to the fields after that tabular import.
#'
#' - `processing = "raw"` returns a lossless tabular representation: every
#'   field is character, including dates and numbers, while empty strings,
#'   whitespace, sentinels and malformed representations remain visible. This
#'   is not a byte-for-byte copy because encoding is decoded and period files
#'   are combined.
#' - `processing = "typed"` parses the documented column classes. Dates become
#'   `Date`, times become `hms`, numeric fields become integer or double,
#'   empty fields become `NA`, and identifiers remain character. Category
#'   labels, padding and explicit source sentinels otherwise remain unchanged.
#' - `processing = "clean"` starts from the typed import, then trims text, maps
#'   `"NAO DISPONIVEL"` to `NA`, orders ordinal columns, parses `ano_mes_*`,
#'   converts crash-type flags to logical, converts `tempo_sinistro_obito` to
#'   integer, removes a trailing `".0"` from `numero_logradouro`, and validates
#'   coordinate pairs against the Sao Paulo state boundary with a 2 km buffer.
#'   Missing `qtd_*` counts remain `NA`.
#'
#' Before converting a closed-domain column, the cleaning step validates its
#' observed values. If an ordinal column, crash-type flag or integer field
#' contains an unexpected representation, the entire source column is preserved
#' and a warning identifies the new values. This prevents upstream changes from
#' becoming missing values or incorrect `FALSE` values silently.
#'
#' Label harmonisation is selective and opt-in. `standardize = "municipios"`
#' uses official IBGE municipality names keyed by `cod_ibge` and harmonises the
#' spelling of INFOSIGA administrative regions. `"cores"` merges case and gender
#' variants of basic vehicle colours, while preserving detailed liveries and
#' multi-tone values. `"profissoes"` applies consistent title case and known
#' missing-value markers to occupation labels. These transformations preserve
#' the rows and columns and never create broader analytical categories.
#'
#' A small fraction of rows in the source contain data-quality issues (for
#' example, an unescaped `;` inside a street name, or mis-encoded coordinates).
#' In typed and clean modes, values that cannot be parsed to their declared
#' column type become `NA` and are recorded by [readr::problems()]. Raw mode
#' preserves those field values as character. Structural CSV problems are
#' recorded in every mode.
#'
#' Coverage, field definitions and analytical caveats are documented in the
#' searchable online data dictionary returned by [dictionary_infosiga()]. In
#' particular, data from 2015--2018 cover fatal crashes only, while data from
#' 2019 onward also include non-fatal crashes and notifications.
#'
#' @seealso [dictionary_infosiga()].
#'
#' @examples
#' \dontrun{
#' # Import all occurrence records, cleaned (downloads on first use)
#' sinistros <- read_infosiga("sinistros")
#' levels(sinistros$dia_da_semana)
#'
#' # Import all victims / people involved
#' vitimas <- read_infosiga("pessoas")
#'
#' # Lossless tabular import: every field is character
#' raw <- read_infosiga("sinistros", processing = "raw")
#'
#' # Parse documented classes without further cleaning
#' typed <- read_infosiga("sinistros", processing = "typed")
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
read_infosiga <- function(
  dataset = c("sinistros", "pessoas", "veiculos"),
  processing = c("clean", "typed", "raw"),
  standardize = NULL,
  refresh = FALSE,
  quiet = FALSE
) {
  dataset <- match.arg(dataset)
  processing <- match.arg(processing)

  if (!is.logical(refresh) || length(refresh) != 1L || is.na(refresh)) {
    cli::cli_abort("{.arg refresh} must be `TRUE` or `FALSE`.")
  }
  if (!is.null(standardize) && processing != "clean") {
    cli::cli_abort(
      "{.arg standardize} requires the {.val clean} processing mode."
    )
  }

  zip_path <- .infosiga_archive_path()
  cached <- file.exists(zip_path) && !refresh
  if (!file.exists(zip_path) && !refresh) {
    .infosiga_confirm_download()
  }
  zip_path <- .infosiga_download(refresh = refresh, quiet = quiet)

  members <- .archive_members(zip_path, dataset)
  if (length(members) == 0) {
    cli::cli_abort(c(
      "No {.val {dataset}} files were found inside the cached archive.",
      "i" = "The local copy may be corrupted; try {.code read_infosiga(refresh = TRUE)}."
    ))
  }

  if (!quiet) {
    data_date <- .infosiga_archive_date(zip_path)
    dated <- if (is.na(data_date)) {
      ""
    } else {
      paste0(" (data dated ", format(data_date, "%Y-%m-%d"), ")")
    }
    source <- if (cached) "the local infosigasp cache" else "downloaded data"
    n_files <- length(members)
    cli::cli_alert_info(
      "Reading {.val {dataset}} from {source}{dated} \
       ({n_files} source file{?s})."
    )
  }

  exdir <- tempfile("infosiga_")
  dir.create(exdir)
  on.exit(unlink(exdir, recursive = TRUE), add = TRUE)
  utils::unzip(zip_path, files = members, exdir = exdir)

  is_raw <- processing == "raw"
  spec <- if (is_raw) {
    readr::cols(.default = readr::col_character())
  } else {
    .infosiga_col_spec(dataset)
  }
  locale <- readr::locale(
    encoding = "latin1",
    decimal_mark = ",",
    grouping_mark = "."
  )

  parts <- lapply(file.path(exdir, members), function(f) {
    readr::read_delim(
      f,
      delim = ";",
      col_types = spec,
      locale = locale,
      # Raw mode preserves empty source fields. Typed and clean modes interpret
      # them as missing values before applying their declared column types.
      na = if (is_raw) character() else "",
      trim_ws = FALSE,
      progress = FALSE,
      show_col_types = FALSE
    )
  })
  import_problems <- parts |>
    lapply(readr::problems) |>
    dplyr::bind_rows()

  out <- dplyr::bind_rows(parts)

  out <- tibble::as_tibble(out)

  if (processing == "clean") {
    out <- .infosiga_clean(out, dataset)
  }

  if (!is.null(standardize)) {
    out <- .infosiga_standardize(out, dataset, standardize)
  }
  attr(out, "problems") <- import_problems

  if (!quiet) {
    mode <- if (!is.null(standardize)) {
      "clean and standardised"
    } else {
      processing
    }
    cli::cli_alert_success(
      "Imported {nrow(out)} row{?s} and {ncol(out)} columns of {mode} {.val {dataset}}."
    )
  }
  out
}

.infosiga_confirm_download <- function(
  is_interactive = interactive(),
  ask = utils::askYesNo
) {
  if (!is_interactive) {
    return(invisible(TRUE))
  }

  cli::cli_inform(c(
    "INFOSIGA-SP data are not available locally.",
    "i" = "The download is approximately 120 MB and will be stored in your user cache."
  ))
  confirmed <- ask("Download now?", default = TRUE)
  if (!isTRUE(confirmed)) {
    cli::cli_abort("Download cancelled; no files were added to your cache.")
  }
  invisible(TRUE)
}

# Return the archive members (CSV file names) for a dataset, matched by the
# `<dataset>_<from>-<to>.csv` naming pattern.
.archive_members <- function(zip_path, dataset) {
  listing <- utils::unzip(zip_path, list = TRUE)
  pattern <- .infosiga_members(dataset)
  stringr::str_subset(listing$Name, pattern)
}
