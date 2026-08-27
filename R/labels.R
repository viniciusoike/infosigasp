# Label harmonisation -----------------------------------------------------
#
# Everything in this file is opt-in and deliberately separate from
# .infosiga_clean(), which stays faithful to the published categories. Users
# reproducing a DETRAN-SP figure need the source labels verbatim; users doing
# their own analysis usually want equivalent labels to group correctly. These
# helpers perform conservative harmonisation without analytical recoding.
#
# Accented literals are built with intToUtf8() so the source file stays pure
# ASCII and portable, matching the convention in clean.R.

# Portuguese connectives stay lower case inside a name ("Rota das Bandeiras",
# "Administrador de Empresas"), unless they lead the string.
.pt_lowercase_words <- c(
  "a",
  "as",
  "ao",
  "aos",
  "com",
  "da",
  "das",
  "de",
  "do",
  "dos",
  "e",
  "em",
  "na",
  "nas",
  "no",
  "nos",
  "o",
  "os",
  "ou",
  "para",
  "por"
)

.capitalise <- function(x) {
  paste0(toupper(substring(x, 1, 1)), substring(x, 2))
}

# Title-case a Portuguese phrase. Words start at the beginning of the string
# or after a space, hyphen or slash, so "MOTO-BOY" becomes "Moto-Boy" and
# "AEROVIARIO/AERONAUTA" becomes "Aeroviario/Aeronauta". Lower-casing first
# means the gendered "(A)" suffix comes out as "Autonomo(a)".
.pt_title_case <- function(x) {
  out <- gsub("(^|[ /-])([[:alpha:]])", "\\1\\U\\2", tolower(x), perl = TRUE)
  # Demote the connectives again, but never the leading word: the lookbehind
  # requires a preceding space, so a string-initial "Do" is left alone.
  for (w in .pt_lowercase_words) {
    out <- gsub(
      paste0("(?<= )", .capitalise(w), "(?=( |$))"),
      w,
      out,
      perl = TRUE
    )
  }
  out
}

# Canonical vehicle colours. The source carries the same colour under two
# spellings (an upper-case stream and a title-case one, with inconsistent
# gender: "PRETA" alongside "Preta", "BRANCA" alongside "Branco"). Fleet
# liveries and multi-tone values pass through unchanged: grouping them would be
# an analytical recode rather than label harmonisation.
.cor_veiculo_map <- c(
  "AMARELA" = "Amarela",
  "Amarelo" = "Amarela",
  "AZUL" = "Azul",
  "Azul" = "Azul",
  "BEGE" = "Bege",
  "Bege" = "Bege",
  "BRANCA" = "Branca",
  "Branco" = "Branca",
  "CINZA" = "Cinza",
  "Cinza" = "Cinza",
  "DOURADA" = "Dourada",
  "Dourada" = "Dourada",
  "FANTASIA" = "Fantasia",
  "Fantasia" = "Fantasia",
  "GRENA" = "Grena",
  "Grena" = "Grena",
  "LARANJA" = "Laranja",
  "Laranja" = "Laranja",
  "MARROM" = "Marrom",
  "Marrom" = "Marrom",
  "PRATA" = "Prata",
  "Prata" = "Prata",
  "PRETA" = "Preta",
  "Preta" = "Preta",
  "ROSA" = "Rosa",
  "Rosa" = "Rosa",
  "ROXA" = "Roxa",
  "Roxa" = "Roxa",
  "VERDE" = "Verde",
  "Verde" = "Verde",
  "VERMELHA" = "Vermelha",
  "Vermelho" = "Vermelha",
  # Markers the source spells differently from "NAO DISPONIVEL". Built with
  # intToUtf8() so this file stays ASCII: 0x00c7 is C-cedilla, 0x00c3 A-tilde,
  # 0x00e3 a-tilde.
  NA_character_,
  NA_character_
)
names(.cor_veiculo_map)[length(.cor_veiculo_map) - 1:0] <- c(
  paste0("SEM IDENTIFICA", intToUtf8(0x00c7), intToUtf8(0x00c3), "O"),
  paste0("N", intToUtf8(0x00e3), "o Informado")
)

# Missing-value markers observed specifically in profissao. Keeping this rule
# column-specific avoids treating the same literal as missing in another domain
# without evidence. Compared after accent folding, so only one spelling of each
# is needed here.
.profissao_na_markers <- c(
  "NAO INFORMADO",
  "NAO INFORMADA",
  "NAO IDENTIFICADO",
  "NAO IDENTIFICADA",
  "SEM INFORMACAO",
  "SEM INFORMACOES",
  "SEM IDENTIFICACAO",
  "DESCONHECIDO",
  "DESCONHECIDA",
  "NAO DISPONIVEL",
  "-"
)

# Fold Portuguese accented letters to plain ASCII. chartr() rather than
# iconv(to = "ASCII//TRANSLIT"), which is locale- and platform-dependent (on
# macOS the latter renders A-tilde as a free-standing "~A").
.ascii_fold <- function(x) {
  chartr(
    intToUtf8(c(
      0x00c1,
      0x00c0,
      0x00c2,
      0x00c3,
      0x00c4, # A with acute/grave/circumflex/tilde/diaeresis
      0x00c9,
      0x00c8,
      0x00ca,
      0x00cb, # E
      0x00cd,
      0x00cc,
      0x00ce,
      0x00cf, # I
      0x00d3,
      0x00d2,
      0x00d4,
      0x00d5,
      0x00d6, # O
      0x00da,
      0x00d9,
      0x00db,
      0x00dc, # U
      0x00c7,
      0x00d1 # C-cedilla, N-tilde
    )),
    "AAAAAEEEEIIIIOOOOOUUUUCN",
    x
  )
}

# TRUE where a value is one of the source's assorted missing-value markers,
# compared case- and accent-insensitively.
.matches_profissao_na_marker <- function(x) {
  !is.na(x) &
    .ascii_fold(stringr::str_to_upper(stringr::str_trim(x))) %in%
      .ascii_fold(.profissao_na_markers)
}

# Standardise selected labels in an INFOSIGA-SP dataset
#
# An opt-in companion to [.infosiga_clean()] that rewrites selected labels
# into a consistent form: Title Case, accents restored where an authoritative
# spelling exists, duplicate categories merged, and known "not informed"
# strings mapped to `NA`. It does not aggregate categories or reshape fields.
#
# It stays separate from [.infosiga_clean()], which never touches labels. Use
# `.infosiga_clean()` (or `read_infosiga(processing = "clean")`) when you need
# categories exactly as DETRAN-SP publishes them, for example to reproduce an
# official figure. Use `.infosiga_standardize()` on top of that when you need
# equivalent labels to group consistently.
#
# @param data A data frame from [read_infosiga()] or [.infosiga_clean()].
# @param dataset Which dataset `data` corresponds to: `"sinistros"`,
#   `"pessoas"` or `"veiculos"`. Determines which columns are rewritten.
# @param standardize Character vector selecting the harmonisations to apply, or
#   `"all"` for every harmonisation applicable to `dataset`.
#
# @return A [tibble][tibble::tibble] with the same rows and columns as `data`,
#   with the label changes described in *Details*.
#
# @details
# \subsection{Place names (sinistros, pessoas)}{
# The source publishes `municipio` unaccented and upper case (`"SAO PAULO"`)
# but `regiao_administrativa` with its accents intact, so neither can be
# joined to other Brazilian data as published. Municipality names take the
# official IBGE spelling, matched on `cod_ibge` and never on the name;
# administrative-region names retain INFOSIGA's classification with consistent
# accents and case. Nine municipality names differ between INFOSIGA and IBGE:
# eight apostrophes that INFOSIGA renders as spaces (`"SANTA BARBARA D OESTE"`),
# plus IBGE's authoritative `"Sao Luiz do Paraitinga"` against INFOSIGA's
# `"SAO LUIS DO PARAITINGA"`. See [infosiga_municipios].
# }
#
# \subsection{Vehicle colour (veiculos)}{
# `cor_veiculo` carries dozens of distinct values for roughly sixteen real
# colours, because two upstream systems coexist in every year: an upper-case
# stream (`"PRETA"`, `"BRANCA"`) and a title-case one with different gender
# agreement (`"Preta"`, `"Branco"`). Note that `toupper()` alone will *not*
# merge these. Values map onto a canonical set only when they identify a basic
# colour.
# Liveries, multi-tone colours and unrecognised values pass through unchanged,
# so harmonisation never discards a more detailed source category.
# }
#
# \subsection{Occupation (pessoas)}{
# `profissao` is Title Cased, which merges the several hundred values that
# differ from another value only by capitalisation, and `"NAO INFORMADA"` /
# `"Nao informada"` become `NA`. Accents are **not** restored here and
# occupations are **not** grouped semantically, because no authoritative
# spelling list covers these free-text values. Expect near-duplicates to
# remain.
# }
#
# Every step is idempotent: calling `.infosiga_standardize()` on an
# already-standardised dataset changes nothing.
#
# @seealso [.infosiga_clean()] for the faithful processing this builds on, and
#   [infosiga_municipios] for the municipality lookup.
#
# @examples
# raw <- readr::read_delim(
#   system.file("extdata", "veiculos_sample.csv", package = "infosigasp"),
#   delim = ";", show_col_types = FALSE
# )
# standardised <- .infosiga_standardize(
#   .infosiga_clean(raw, "veiculos"),
#   "veiculos",
#   "cores"
# )
# sort(unique(standardised$cor_veiculo))
.infosiga_standardize <- function(
  data,
  dataset = c(
    "sinistros",
    "pessoas",
    "veiculos"
  ),
  standardize = "all"
) {
  dataset <- match.arg(dataset)
  applicable <- list(
    sinistros = "municipios",
    pessoas = c("municipios", "profissoes"),
    veiculos = "cores"
  )
  allowed <- unique(unlist(applicable, use.names = FALSE))

  if (
    !is.character(standardize) || length(standardize) == 0 || anyNA(standardize)
  ) {
    cli::cli_abort(
      "{.arg standardize} must be a non-empty character vector or {.val all}."
    )
  }

  unknown <- setdiff(standardize, c(allowed, "all"))
  if (length(unknown) > 0) {
    cli::cli_abort(c(
      "Unknown {.arg standardize} value{?s}: {.val {unknown}}.",
      "i" = "Choose from {.val {allowed}} or {.val all}."
    ))
  }

  if ("all" %in% standardize && length(unique(standardize)) > 1) {
    cli::cli_abort(
      "{.val all} cannot be combined with individual {.arg standardize} values."
    )
  }

  if ("all" %in% standardize) {
    standardize <- applicable[[dataset]]
  }

  unavailable <- setdiff(standardize, applicable[[dataset]])
  if (length(unavailable) > 0) {
    cli::cli_abort(c(
      "Some requested standardisations are not available for {.val {dataset}}: {.val {unavailable}}.",
      "i" = "Available for this dataset: {.val {applicable[[dataset]]}}."
    ))
  }
  standardize <- unique(standardize)

  # Place names, matched on cod_ibge rather than on the name itself. Rows whose
  # code is missing or unknown keep whatever they already had.
  if ("municipios" %in% standardize && "cod_ibge" %in% names(data)) {
    lookup <- infosiga_municipios
    place_cols <- intersect(
      c("municipio", "regiao_administrativa"),
      names(data)
    )

    if (length(place_cols) > 0) {
      lookup <- lookup |>
        dplyr::select(dplyr::all_of(c("cod_ibge", place_cols)))

      data <- dplyr::rows_update(
        data,
        lookup,
        by = "cod_ibge",
        unmatched = "ignore"
      )
    }
  }

  if ("cores" %in% standardize && "cor_veiculo" %in% names(data)) {
    data <- data |>
      dplyr::mutate(
        cor_veiculo = dplyr::replace_values(
          data$cor_veiculo,
          from = names(.cor_veiculo_map),
          to = unname(.cor_veiculo_map)
        )
      )
  }

  if ("profissoes" %in% standardize && "profissao" %in% names(data)) {
    data <- data |>
      dplyr::mutate(
        profissao = dplyr::replace_when(
          data$profissao,
          .matches_profissao_na_marker(data$profissao) ~ NA_character_
        )
      )

    data <- data |>
      dplyr::mutate(
        profissao = .pt_title_case(data$profissao)
      )
  }

  tibble::as_tibble(data)
}
