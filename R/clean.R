# Ordered-factor level definitions for the ordinal columns. Accented level
# names are built with intToUtf8() so the source file stays pure ASCII and
# portable, while the values are UTF-8 (matching the decoded Latin-1 source):
#   0x00e7 is c-cedilla, 0x00e1 is a-acute.
.infosiga_factor_levels <- list(
  # Brazilian calendars start the week on Sunday (Domingo).
  dia_da_semana = c(
    "Domingo",
    "Segunda-feira",
    paste0("Ter", intToUtf8(0x00e7), "a-feira"),
    "Quarta-feira",
    "Quinta-feira",
    "Sexta-feira",
    paste0("S", intToUtf8(0x00e1), "bado")
  ),
  # Periods of the day, in chronological order.
  turno = c("MADRUGADA", "MANHA", "TARDE", "NOITE"),
  # Injury severity, from least to most severe.
  gravidade_lesao = c("LEVE", "GRAVE", "FATAL"),
  faixa_etaria_demografica = c(
    "00 a 04",
    "05 a 09",
    "10 a 14",
    "15 a 19",
    "20 a 24",
    "25 a 29",
    "30 a 34",
    "35 a 39",
    "40 a 44",
    "45 a 49",
    "50 a 54",
    "55 a 59",
    "60 a 64",
    "65 a 69",
    "70 a 74",
    "75 a 79",
    "80 a 84",
    "85 a 89",
    "90 e +"
  ),
  faixa_etaria_legal = c(
    "0-17",
    "18-24",
    "25-29",
    "30-34",
    "35-39",
    "40-44",
    "45-49",
    "50-54",
    "55-59",
    "60-64",
    "65-69",
    "70-74",
    "75-79",
    "80 ou mais"
  )
)

# Parse the source "YYYY/MM" year-month strings into first-of-month Dates.
# Empty strings and other non-matching values become NA.
.parse_ano_mes <- function(x) {
  as.Date(paste0(x, "/01"), format = "%Y/%m/%d")
}

# Warn about values outside a documented source domain. Callers preserve the
# original column when this returns FALSE, rather than silently losing values
# through coercion.
.infosiga_has_known_values <- function(x, known, column) {
  unexpected <- setdiff(unique(as.character(stats::na.omit(x))), known)

  if (length(unexpected) == 0) {
    return(TRUE)
  }

  cli::cli_warn(c(
    "Column {.field {column}} contains unexpected source values and was left unchanged.",
    "i" = "Expected: {.val {known}}.",
    "i" = "Found: {.val {unexpected}}."
  ))
  FALSE
}

.infosiga_as_ordered <- function(x, levels, column) {
  if (!.infosiga_has_known_values(x, levels, column)) {
    return(x)
  }

  factor(x, levels = levels, ordered = TRUE)
}

.infosiga_as_flag <- function(x, column) {
  if (!.infosiga_has_known_values(x, "S", column)) {
    return(x)
  }

  !is.na(x)
}

.infosiga_as_integer <- function(x, column) {
  has_integer_format <- is.na(x) | stringr::str_detect(x, "^[+-]?[0-9]+$")
  converted <- suppressWarnings(as.integer(x))
  is_representable <- is.na(x) | !is.na(converted)
  is_valid <- has_integer_format & is_representable

  if (!all(is_valid)) {
    unexpected <- unique(x[!is_valid])
    cli::cli_warn(c(
      "Column {.field {column}} contains unexpected source values and was left unchanged.",
      "i" = "Expected integer strings.",
      "i" = "Found: {.val {unexpected}}."
    ))
    return(x)
  }

  converted
}

# Validate coordinate pairs against the buffered Sao Paulo state boundary.
# A bounding-box prefilter cheaply rejects malformed coordinates before the
# spatial predicate and avoids passing invalid latitude values to s2.
.infosiga_valid_coordinates <- function(latitude, longitude) {
  valid <- rep(FALSE, length(latitude))
  boundary <- sf::st_bbox(spo_shape)

  candidates <- is.finite(latitude) &
    is.finite(longitude) &
    dplyr::between(latitude, boundary[["ymin"]], boundary[["ymax"]]) &
    dplyr::between(longitude, boundary[["xmin"]], boundary[["xmax"]])

  if (!any(candidates)) {
    return(valid)
  }

  points <- sf::st_as_sf(
    data.frame(
      longitude = longitude[candidates],
      latitude = latitude[candidates]
    ),
    coords = c("longitude", "latitude"),
    crs = 4326
  )

  valid[candidates] <- lengths(sf::st_intersects(points, spo_shape)) > 0
  valid
}

# Clean and process an INFOSIGA-SP dataset
#
# Applies the standard processing that [read_infosiga()] performs by default
# (`processing = "clean"`). It receives the typed representation created by
# [read_infosiga()] before the optional standardisation layer.
#
# The processing standardises missing values, fixes source formatting
# artefacts and assigns meaningful types to columns whose published
# representation is inconvenient (ordinal text, binary flags, year-month
# strings). It never renames columns, recodes category labels or drops rows.
#
# @param data A typed INFOSIGA-SP data frame.
# @param dataset Which dataset `data` corresponds to: `"sinistros"`,
#   `"pessoas"` or `"veiculos"`. Determines which columns are processed.
#
# @return A [tibble][tibble::tibble] with the same columns as `data`, with the
#   processing described in *Details* applied.
#
# @details
# `.infosiga_clean()` applies the following steps, in order. Every step is
# idempotent, so calling the function again on an already-processed dataset
# changes nothing.
#
# \enumerate{
#   \item **Whitespace.** Trims leading and trailing whitespace from every text
#     column. Some source fields are space-padded to a fixed width (for example
#     `nacionalidade` is published as `"BRASILEIRA          "`); without
#     trimming, comparisons, grouping and joins on those columns silently fail.
#   \item **Missing values.** Replaces the literal `"NAO DISPONIVEL"` ("not
#     available") marker with `NA` in every text column. Trimming runs first,
#     so space-padded markers are also caught.
#   \item **Ordered factors.** Ordinal columns become **ordered factors** in
#     their natural order.
#     \itemize{
#       \item `dia_da_semana`: `Domingo` < ... < `Sabado` (the Brazilian week
#         starts on Sunday).
#       \item `turno`: `MADRUGADA` < `MANHA` < `TARDE` < `NOITE`.
#       \item `gravidade_lesao` (in `pessoas`): `LEVE` < `GRAVE` < `FATAL`.
#       \item `faixa_etaria_demografica`, `faixa_etaria_legal` (in `pessoas`):
#         age bands in increasing order.
#     }
#   \item **Year-month dates.** Parses the year-month columns
#     (`ano_mes_sinistro`, `ano_mes_obito`), published as `"YYYY/MM"` strings,
#     to first-of-month `Date` values, matching the `Date` class already used
#     for the full-date columns.
#   \item **Crash-type flags** (`sinistros`). The binary `tp_sinistro_*`
#     columns become **logical** (`TRUE` / `FALSE`). They mark whether a crash
#     involved a given event type and are published as `"S"` (yes) or empty
#     (no). The categorical `tp_sinistro_primario` (the primary crash type,
#     e.g. `"COLISAO"`) is *not* a flag and stays text.
#     `tp_sinistro_colisao_traseira` is empty for every record in the source
#     and therefore becomes uniformly `FALSE`. That is an unpopulated upstream
#     field, not evidence that no rear-end collisions occurred. A crash may
#     also set several flags at once, so the flags do not partition the data.
#   \item **Count columns** (`sinistros`). Missing `qtd_*` values remain `NA`.
#     Clean mode does not infer that a blank count is zero, even when another
#     vehicle or victim-severity count is available for the same crash.
#   \item **Days to death** (`pessoas`). `tempo_sinistro_obito`, the number of
#     days between the crash and the victim's death (published as a numeric
#     string), becomes **integer**.
#   \item **Street numbers and kilometre markers** (`sinistros`).
#     `numero_logradouro` carries a house number on urban streets but a
#     **kilometre marker** on highways, where a fractional part is meaningful
#     (`"0.25"` is km 250 m, not a malformed house number). Genuine decimals
#     are common on `ESTRADAS E RODOVIAS` rows and rare on `VIAS URBANAS` ones.
#     Only a trailing `".0"` from the source export is stripped (`"193.0"` ->
#     `"193"`); any other decimal part survives. The column stays character
#     because the two meanings are not comparable on a single numeric scale.
#   \item **Coordinates** (`sinistros`). Validates `latitude`/`longitude` as a
#     pair against the boundary of Sao Paulo state with a 2 km buffer. Points
#     outside the buffered boundary, including mis-encoded values and `(0, 0)`
#     "null island" placeholders, have both coordinates set to `NA`. This
#     affects a few percent of records and drops no rows. Use
#     `processing = "typed"` or `"raw"` if you need the coordinates before this
#     validation.
# }
#
# Nominal text columns (such as `municipio`, `tipo_via` or `sexo`) stay
# character vectors. Well-typed numeric columns, notably `idade` (the victim's
# age, in `pessoas`), pass through unchanged and are *not* range-checked.
# Missing ages are `NA` and ages of `0` (infants) are kept. The package
# enforces no bound on `idade`, so validate it yourself if your analysis is
# sensitive to outliers.
#
# @seealso [read_infosiga()], which calls this function in `"clean"` mode.
#
# @examples
# # Process the bundled raw sample
# raw <- readr::read_delim(
#   system.file("extdata", "pessoas_sample.csv", package = "infosigasp"),
#   delim = ";", show_col_types = FALSE
# )
# clean <- .infosiga_clean(raw, "pessoas")
# levels(clean$gravidade_lesao)
# @export
.infosiga_clean <- function(
  data,
  dataset = c("sinistros", "pessoas", "veiculos")
) {
  dataset <- match.arg(dataset)

  # 1. Trim whitespace, then standardise the "not available" marker to NA, in
  #    every text column. Some source fields are space-padded to a fixed width
  #    (e.g. nacionalidade); trimming first ensures padded "NAO DISPONIVEL"
  #    markers are caught and that grouping/joins on those columns behave.
  data <- data |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(is.character),
        function(x) {
          x |>
            stringr::str_trim() |>
            dplyr::replace_values("NAO DISPONIVEL" ~ NA_character_)
        }
      )
    )

  # 2. Ordinal columns become ordered factors. If the source introduces an
  #    unexpected value, preserve that entire column and warn rather than
  #    silently converting the new value to NA.
  factor_cols <- intersect(names(.infosiga_factor_levels), names(data))

  data <- data |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(factor_cols),
        function(x) {
          .infosiga_as_ordered(
            x,
            levels = .infosiga_factor_levels[[dplyr::cur_column()]],
            column = dplyr::cur_column()
          )
        }
      )
    )

  # 3. Year-month columns ("YYYY/MM") become first-of-month Dates, matching
  #    the Date class already used for the full-date columns. The is.character
  #    guard keeps the step idempotent (parsed Dates are left untouched).
  ano_mes_cols <- data |>
    dplyr::select(
      dplyr::starts_with("ano_mes_") & dplyr::where(is.character)
    ) |>
    names()

  data <- data |>
    dplyr::mutate(
      dplyr::across(dplyr::all_of(ano_mes_cols), .parse_ano_mes)
    )

  # 4. Crash-type flags ("S"/empty) become logical. Unexpected non-missing
  #    tokens leave the entire column unchanged and produce a warning.
  #    tp_sinistro_primario is categorical, not a flag, so it is excluded.
  flag_cols <- data |>
    dplyr::select(
      dplyr::starts_with("tp_sinistro_") & dplyr::where(is.character),
      -dplyr::any_of("tp_sinistro_primario")
    ) |>
    names()

  data <- data |>
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(flag_cols),
        \(x) .infosiga_as_flag(x, dplyr::cur_column())
      )
    )

  # 5. tempo_sinistro_obito (days from crash to death) becomes integer. Preserve
  #    the source column and warn if any non-missing value is not an integer.
  if (
    "tempo_sinistro_obito" %in%
      names(data) &&
      is.character(data$tempo_sinistro_obito)
  ) {
    data <- data |>
      dplyr::mutate(
        tempo_sinistro_obito = .infosiga_as_integer(
          data$tempo_sinistro_obito,
          "tempo_sinistro_obito"
        )
      )
  }

  # 6. Strip the spurious trailing ".0" the source export appends ("193.0" ->
  #    "193"). The "\\.0$" anchor matters: on highways this column holds a
  #    kilometre marker whose decimal part is real ("0.25"), so only an exactly
  #    zero fraction is dropped. The column stays character because a house
  #    number and a kilometre marker are not the same quantity.
  if (
    "numero_logradouro" %in% names(data) && is.character(data$numero_logradouro)
  ) {
    data <- data |>
      dplyr::mutate(
        numero_logradouro = stringr::str_remove(
          data$numero_logradouro,
          "\\.0$"
        )
      )
  }

  # 7. Coordinates are validated as a pair against the buffered Sao Paulo
  #    state boundary. Otherwise both are set to NA.
  if (all(c("latitude", "longitude") %in% names(data))) {
    valid_coordinates <- .infosiga_valid_coordinates(
      data$latitude,
      data$longitude
    )

    data <- data |>
      dplyr::mutate(
        dplyr::across(
          dplyr::all_of(c("latitude", "longitude")),
          \(x) dplyr::replace_when(x, !valid_coordinates ~ NA_real_)
        )
      )
  }

  tibble::as_tibble(data)
}
