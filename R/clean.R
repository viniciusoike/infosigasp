# Ordered-factor level definitions for the ordinal columns. Accented level
# names are built with intToUtf8() so the source file stays pure ASCII and
# portable, while the values are UTF-8 (matching the decoded Latin-1 source):
#   0x00e7 is c-cedilla, 0x00e1 is a-acute.
.infosiga_factor_levels <- list(
  # Brazilian calendars start the week on Sunday (Domingo).
  dia_da_semana = c(
    "Domingo", "Segunda-feira",
    paste0("Ter", intToUtf8(0x00e7), "a-feira"),
    "Quarta-feira", "Quinta-feira", "Sexta-feira",
    paste0("S", intToUtf8(0x00e1), "bado")
  ),
  # Periods of the day, in chronological order.
  turno = c("MADRUGADA", "MANHA", "TARDE", "NOITE"),
  # Injury severity, from least to most severe.
  gravidade_lesao = c("LEVE", "GRAVE", "FATAL"),
  faixa_etaria_demografica = c(
    "00 a 04", "05 a 09", "10 a 14", "15 a 19", "20 a 24", "25 a 29",
    "30 a 34", "35 a 39", "40 a 44", "45 a 49", "50 a 54", "55 a 59",
    "60 a 64", "65 a 69", "70 a 74", "75 a 79", "80 a 84", "85 a 89", "90 e +"
  ),
  faixa_etaria_legal = c(
    "0-17", "18-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54",
    "55-59", "60-64", "65-69", "70-74", "75-79", "80 ou mais"
  )
)

# Parse the source "YYYY/MM" year-month strings into first-of-month Dates.
# Empty strings and other non-matching values become NA.
.parse_ano_mes <- function(x) {
  as.Date(paste0(x, "/01"), format = "%Y/%m/%d")
}

# Bounding box of the state of Sao Paulo, with a small margin so genuine
# near-border crashes are kept. The state spans roughly latitude -25.4..-19.8
# and longitude -53.1..-44.2; coordinates outside this box (mis-encoded values
# and "null island" 0,0 placeholders) are treated as errors.
.sp_bbox <- list(lat = c(-25.6, -19.5), lon = c(-53.3, -44.0))

#' Clean and process an INFOSIGA-SP dataset
#'
#' Applies the standard processing that [read_infosiga()] performs by default
#' (`clean = TRUE`). Use this directly only when you imported a dataset with
#' `clean = FALSE` (the raw version) and want to process it afterwards.
#'
#' The processing is deliberately light: it standardises missing values, fixes
#' source formatting artefacts and assigns meaningful types to columns whose
#' published representation is inconvenient (ordinal text, binary flags,
#' year-month strings). It never renames columns, recodes category labels or
#' drops rows, so the result stays a faithful, analysis-ready view of the
#' source.
#'
#' @param data A data frame imported with [read_infosiga()] (typically with
#'   `clean = FALSE`).
#' @param dataset Which dataset `data` corresponds to: `"sinistros"`,
#'   `"pessoas"` or `"veiculos"`. Determines which columns are processed.
#'
#' @return A [tibble][tibble::tibble] with the same columns as `data`, with the
#'   processing described in *Details* applied.
#'
#' @details
#' The following steps are applied, in order. Every step is idempotent, so
#' `clean_infosiga()` can be called again on an already-processed dataset
#' without changing it.
#'
#' \enumerate{
#'   \item **Whitespace.** Leading and trailing whitespace is trimmed from every
#'     text column. Some source fields are space-padded to a fixed width (for
#'     example `nacionalidade` is published as `"BRASILEIRA          "`); without
#'     trimming, comparisons, grouping and joins on those columns silently fail.
#'   \item **Missing values.** The literal `"NAO DISPONIVEL"` ("not available")
#'     marker is replaced by `NA` in every text column. Trimming happens first
#'     so that space-padded markers are also caught.
#'   \item **Ordered factors.** Ordinal columns are converted to **ordered
#'     factors** with their natural order:
#'     \itemize{
#'       \item `dia_da_semana`: `Domingo` < ... < `Sabado` (the Brazilian week
#'         starts on Sunday).
#'       \item `turno`: `MADRUGADA` < `MANHA` < `TARDE` < `NOITE`.
#'       \item `gravidade_lesao` (in `pessoas`): `LEVE` < `GRAVE` < `FATAL`.
#'       \item `faixa_etaria_demografica`, `faixa_etaria_legal` (in `pessoas`):
#'         age bands in increasing order.
#'     }
#'   \item **Year-month dates.** Year-month columns (`ano_mes_sinistro`,
#'     `ano_mes_obito`), published as `"YYYY/MM"` strings, are parsed to
#'     first-of-month `Date` values, matching the `Date` class already used for
#'     the full-date columns.
#'   \item **Crash-type flags** (`sinistros`). The binary `tp_sinistro_*`
#'     columns -- which mark whether a crash involved a given event type and are
#'     published as `"S"` (yes) or empty (no) -- become **logical** (`TRUE` /
#'     `FALSE`). The categorical `tp_sinistro_primario` (the primary crash type,
#'     e.g. `"COLISAO"`) is *not* a flag and is left as text.
#'   \item **Days to death** (`pessoas`). `tempo_sinistro_obito`, the number of
#'     days between the crash and the victim's death (published as a numeric
#'     string), becomes **integer**.
#'   \item **Street numbers** (`sinistros`). `numero_logradouro` is kept as text
#'     (house numbers may contain letters), but a spurious trailing `".0"` from
#'     the source export (`"193.0"`) is stripped to `"193"`.
#'   \item **Coordinates** (`sinistros`). `latitude`/`longitude` are validated as
#'     a pair against the bounding box of the state of Sao Paulo. Points outside
#'     the box -- mis-encoded values and `(0, 0)` "null island" placeholders --
#'     have both coordinates set to `NA`. This affects roughly 7% of records;
#'     no rows are dropped. Use `clean = FALSE` if you need the raw coordinates.
#' }
#'
#' Nominal text columns (such as `municipio`, `tipo_via` or `sexo`) are left as
#' character vectors. Numeric columns that are already well typed -- notably
#' `idade` (the victim's age, in `pessoas`) -- are passed through unchanged and
#' are *not* range-checked: missing ages are `NA`, and ages of `0` (infants)
#' are kept. In the current upstream data `idade` ranges from 0 to about 102,
#' but the package does not enforce any bound, so validate it yourself if your
#' analysis is sensitive to outliers.
#'
#' @seealso [read_infosiga()], which calls this function when `clean = TRUE`.
#'
#' @examples
#' # Process the bundled raw sample
#' raw <- readr::read_delim(
#'   system.file("extdata", "pessoas_sample.csv", package = "infosigasp"),
#'   delim = ";", show_col_types = FALSE
#' )
#' clean <- clean_infosiga(raw, "pessoas")
#' levels(clean$gravidade_lesao)
#' @export
clean_infosiga <- function(data, dataset = c("sinistros", "pessoas", "veiculos")) {
  dataset <- match.arg(dataset)

  # 1. Trim whitespace, then standardise the "not available" marker to NA, in
  #    every text column. Some source fields are space-padded to a fixed width
  #    (e.g. nacionalidade); trimming first ensures padded "NAO DISPONIVEL"
  #    markers are caught and that grouping/joins on those columns behave.
  char_cols <- names(data)[vapply(data, is.character, logical(1))]
  for (col in char_cols) {
    v <- trimws(data[[col]])
    v[v == "NAO DISPONIVEL"] <- NA
    data[[col]] <- v
  }

  # 2. Ordinal columns become ordered factors. Values outside the known levels
  #    (e.g. the just-removed marker) map to NA.
  for (col in names(.infosiga_factor_levels)) {
    if (col %in% names(data)) {
      data[[col]] <- factor(
        data[[col]],
        levels = .infosiga_factor_levels[[col]],
        ordered = TRUE
      )
    }
  }

  # 3. Year-month columns ("YYYY/MM") become first-of-month Dates, matching
  #    the Date class already used for the full-date columns. The is.character
  #    guard keeps the step idempotent (parsed Dates are left untouched).
  ano_mes_cols <- grep("^ano_mes_", names(data), value = TRUE)
  for (col in ano_mes_cols) {
    if (is.character(data[[col]])) data[[col]] <- .parse_ano_mes(data[[col]])
  }

  # 4. Crash-type flags ("S"/empty) become logical. tp_sinistro_primario is a
  #    categorical column, not a flag, so it is excluded.
  flag_cols <- setdiff(
    grep("^tp_sinistro_", names(data), value = TRUE),
    "tp_sinistro_primario"
  )
  for (col in flag_cols) {
    v <- data[[col]]
    if (is.character(v)) data[[col]] <- !is.na(v) & v == "S"
  }

  # 5. tempo_sinistro_obito (days from crash to death) becomes integer.
  if ("tempo_sinistro_obito" %in% names(data) &&
    is.character(data$tempo_sinistro_obito)) {
    data$tempo_sinistro_obito <- suppressWarnings(
      as.integer(data$tempo_sinistro_obito)
    )
  }

  # 6. Strip the spurious trailing ".0" the source export appends to house
  #    numbers ("193.0" -> "193"); the column stays character because numbers
  #    may contain letters.
  if ("numero_logradouro" %in% names(data) &&
    is.character(data$numero_logradouro)) {
    data$numero_logradouro <- sub("\\.0$", "", data$numero_logradouro)
  }

  # 7. Coordinates are validated as a pair against the Sao Paulo bounding box.
  #    A point is kept only if both latitude and longitude are present and
  #    inside the box; otherwise both are set to NA. This drops mis-encoded
  #    values and "null island" (0, 0) placeholders.
  if (all(c("latitude", "longitude") %in% names(data))) {
    lat <- data$latitude
    lon <- data$longitude
    valid <- !is.na(lat) & !is.na(lon) &
      lat >= .sp_bbox$lat[1] & lat <= .sp_bbox$lat[2] &
      lon >= .sp_bbox$lon[1] & lon <= .sp_bbox$lon[2]
    data$latitude[!valid] <- NA_real_
    data$longitude[!valid] <- NA_real_
  }

  tibble::as_tibble(data)
}
