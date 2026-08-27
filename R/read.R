#' Import an INFOSIGA-SP dataset
#'
#' Downloads (if necessary) and imports one of the three INFOSIGA-SP datasets
#' as a tidy tibble. The first interactive call asks before downloading about
#' 120 MB to the user's local cache; subsequent calls read from disk.
#'
#' @param dataset Which dataset to import.
#'   \describe{
#'     \item{`"sinistros"`}{Crash events (one row per event).}
#'     \item{`"pessoas"`}{Victims / people involved (one row per person).}
#'     \item{`"veiculos"`}{Vehicles involved (one row per vehicle).}
#'   }
#' @param year Optional integer vector used to filter rows by year of the
#'   crash (`ano_sinistro`). If `NULL` (default), all available years are
#'   returned. For example, `year = 2020:2023`.
#' @param clean Logical. If `TRUE` (default), return a processed dataset:
#'   text is trimmed, the `"NAO DISPONIVEL"` marker becomes `NA`, ordinal
#'   columns become ordered factors, crash-type flags become logical, and
#'   impossible coordinates become `NA`. If `FALSE`, return the raw data
#'   exactly as published, with all text columns as character vectors.
#' @param labels Logical. If `TRUE`, additionally standardise category labels
#'   for analysis and presentation. This restores authoritative place-name
#'   spellings, applies consistent title case, merges duplicate vehicle-colour
#'   categories and separates road-maintenance codes. Requires `clean = TRUE`.
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
#' separator, `,` as the decimal mark and `DD/MM/YYYY` dates. `read_infosiga()`
#' handles all of these and returns UTF-8 text, `Date` columns and numeric
#' coordinates. Each dataset is distributed across two period files inside the
#' archive (2015-2021 and 2022 onward); they are read and row-bound
#' transparently.
#'
#' By default (`clean = TRUE`) the result is then processed by the package's
#' internal cleaning step: text columns are whitespace-trimmed, the
#' `"NAO DISPONIVEL"` ("not available") marker becomes `NA`, ordinal columns
#' (`dia_da_semana`, `turno`, `gravidade_lesao`, the age bands) become
#' **ordered factors**, the `ano_mes_*` year-month strings are parsed to
#' first-of-month `Date`s, the binary `tp_sinistro_*` crash-type flags become
#' **logical**, blank `qtd_*` counts inside an otherwise-filled block become
#' `0`, `tempo_sinistro_obito` becomes **integer**, and
#' `latitude`/`longitude` values outside the bounding box of Sao Paulo state
#' become `NA`. Pass `clean = FALSE` to obtain the raw data exactly as
#' published, with every text column kept as a character vector and
#' `"NAO DISPONIVEL"` and the source's
#' fixed-width whitespace padding preserved verbatim.
#'
#' A small fraction of rows in the source contain data-quality issues (for
#' example, an unescaped `;` inside a street name, or mis-encoded coordinates).
#' Any value that cannot be parsed to its declared column type is set to `NA`
#' and recorded by [readr::problems()]. Empty fields are read as `NA` in both
#' modes. In the raw data (`clean = FALSE`) the crash-type flag columns
#' (`tp_sinistro_*`) hold `"S"` when the flag applies and `NA` otherwise; with
#' `clean = TRUE` they are converted to logical.
#'
#' @section Coverage and known caveats:
#'
#' The source data are published as a single continuous series from 2015
#' onward, but the *scope* of what is collected has changed over time and
#' several columns carry definitions that are easy to misread. None of these
#' are import errors, so the package does not alter the data; they do,
#' however, invalidate a number of otherwise reasonable analyses.
#'
#' \describe{
#'   \item{**2015--2018 covers fatal crashes only.**}{This is the single most
#'     consequential caveat. Non-fatal records begin in 2019: for 2015--2018
#'     `tipo_registro` is `"SINISTRO FATAL"` for every row, and in `pessoas`
#'     the `"LEVE"` and `"GRAVE"` injury levels do not occur at all. Counting
#'     crashes or victims per year across the whole series therefore shows an
#'     apparent 20-fold jump in 2019 that is entirely an artefact of the
#'     expanded collection scope. **For any trend that includes years before
#'     2019, restrict to fatalities** (`tipo_registro == "SINISTRO FATAL"`, or
#'     `gravidade_lesao == "FATAL"` in `pessoas`); otherwise start the series
#'     in 2019.}
#'   \item{**`tipo_registro` mixes notifications with confirmed crashes.**}{
#'     About a third of `sinistros` rows are `"NOTIFICACAO"`, a reported event
#'     that has not been confirmed as a crash. Treating every row as a crash
#'     overstates the total substantially. Filter on `tipo_registro` according
#'     to whether you want confirmed events only.}
#'   \item{**The most recent months are provisional.**}{DETRAN-SP reclassifies
#'     records as it validates them, so the newest months carry an unusually
#'     high share of `"NOTIFICACAO"` and an artificially low share of confirmed
#'     crashes. The final month or two of any release is also partial. Recent
#'     periods are not comparable with settled ones; drop the tail of the series
#'     before computing trends.}
#'   \item{**`tempo_sinistro_obito` is capped at 30 days.**}{The published
#'     values never exceed 30, matching the 30-day convention for attributing a
#'     death to a crash. Deaths occurring later are not recorded as
#'     crash-related here, so fatality counts are 30-day counts, not lifetime
#'     ones.}
#'   \item{**The `qtd_*` vehicle counts do not always match `veiculos`.**}{
#'     Summing the `qtd_pedestre` .. `qtd_veic_nao_disponivel` columns
#'     disagrees with the number of matching `veiculos` rows for a small share
#'     of crashes, so the two routes to "how many vehicles" give different
#'     answers; pick one and state it. The `qtd_gravidade_*` columns, by
#'     contrast, agree with the `pessoas` row counts for every crash.}
#'   \item{**Coordinate availability varies sharply by year.**}{After the
#'     bounding-box validation described above, nearly every
#'     crash in the middle years of the series has usable coordinates, against a
#'     materially smaller share in the earliest and the most recent years.
#'     Mapped subsets are therefore not a uniform sample over time.}
#'   \item{**Not every crash has victim or vehicle rows.**}{Around a third of
#'     `sinistros` records have no matching row in `pessoas`. Use a left join
#'     when you need to keep all crashes, and expect `NA` on the victim side.}
#' }
#'
#' The figures above describe the 2026 releases and shift slightly as
#' DETRAN-SP revises the data; the structural points do not.
#'
#' @seealso [dictionary_infosiga()].
#'
#' @examples
#' \dontrun{
#' # Import all crash events, processed (downloads the archive on first use)
#' sinistros <- read_infosiga("sinistros")
#' levels(sinistros$dia_da_semana)
#'
#' # Only victims from 2022 and 2023
#' vitimas <- read_infosiga("pessoas", year = 2022:2023)
#'
#' # The raw data, exactly as published
#' raw <- read_infosiga("sinistros", clean = FALSE)
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
  year = NULL,
  clean = TRUE,
  labels = FALSE,
  refresh = FALSE,
  quiet = FALSE
) {
  dataset <- match.arg(dataset)

  if (!is.logical(refresh) || length(refresh) != 1L || is.na(refresh)) {
    cli::cli_abort("{.arg refresh} must be `TRUE` or `FALSE`.")
  }
  if (isTRUE(labels) && !isTRUE(clean)) {
    cli::cli_abort("{.arg labels = TRUE} requires {.arg clean = TRUE}.")
  }

  if (!is.null(year)) {
    year <- suppressWarnings(as.integer(year))
    if (anyNA(year)) {
      cli::cli_abort("{.arg year} must be a vector of integer years.")
    }
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

  spec <- .infosiga_col_spec(dataset)
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
      # Empty fields are the source's missing-value marker. Anything that
      # still fails to parse (a handful of malformed source rows) becomes NA
      # and is surfaced through readr::problems().
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

  if (isTRUE(clean)) {
    out <- .infosiga_clean(out, dataset)
  }

  if (isTRUE(labels)) {
    out <- .infosiga_tidy_labels(out, dataset)
  }

  if (!quiet) {
    mode <- if (!isTRUE(clean)) {
      "raw"
    } else if (isTRUE(labels)) {
      "processed and labelled"
    } else {
      "processed"
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
  grep(pattern, listing$Name, value = TRUE)
}
