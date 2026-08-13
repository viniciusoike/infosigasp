# Opinionated label tidying -----------------------------------------------
#
# Everything in this file is *opt-in* and deliberately separate from
# clean_infosiga(), which stays faithful to the published categories. Users
# reproducing a DETRAN-SP figure need the source labels verbatim; users doing
# their own analysis usually want labels that group and plot correctly. These
# helpers serve the second case only.
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
# gender: "PRETA" alongside "Preta", "BRANCA" alongside "Branco"), plus a tail
# of fleet liveries. Solid-colour liveries fold into their base colour, since
# the column answers "what colour was the vehicle"; genuinely two- or
# three-tone values become "Multicor".
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
  # Single-colour official liveries -> the underlying colour.
  "BRANCA (PADRAO CPAMB" = "Branca",
  "BRANCA (PADRAO CPRV)" = "Branca",
  "BRANCA (PADRAO PM)" = "Branca",
  "BRANCA PADRAO CPTRAN" = "Branca",
  "CINZA BANDEIRANTE" = "Cinza",
  "CINZA PM (PADRAO ROT" = "Cinza",
  # Multi-tone liveries and camouflage.
  "BRANCA/CINZA BANDEIR" = "Multicor",
  "BRANCA/CINZA ESCURO" = "Multicor",
  "BRANCA/VERMELHA" = "Multicor",
  "CIN/VER/PRE" = "Multicor",
  "VERMELHA/PRETA" = "Multicor",
  "CAMUFLADO RURAL" = "Camuflada",
  "CAMUFLADO URBANO" = "Camuflada",
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

# Missing-value markers that clean_infosiga() leaves alone because they are not
# the documented "NAO DISPONIVEL" sentinel. Compared after accent folding, so
# only one spelling of each is needed here.
.extra_na_markers <- c(
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
.matches_na_marker <- function(x) {
  !is.na(x) &
    .ascii_fold(toupper(trimws(x))) %in% .ascii_fold(.extra_na_markers)
}

# A conservacao value that is only digits and dots is a route code ("10.03"),
# not the name of the body that maintains the road.
.is_route_code <- function(x) {
  !is.na(x) & grepl("^[0-9]+(\\.[0-9]+)?$", x)
}

#' Tidy the category labels of an INFOSIGA-SP dataset
#'
#' An **opt-in** companion to [clean_infosiga()] that rewrites category labels
#' into a consistent, presentation-ready form: Title Case, accents restored
#' where an authoritative spelling exists, duplicate categories merged, and the
#' source's assorted "not informed" strings mapped to `NA`.
#'
#' It stays separate from [clean_infosiga()], which never touches labels. Use
#' `clean_infosiga()` (or `read_infosiga(clean = TRUE)`) when you need
#' categories exactly as DETRAN-SP publishes them, for example to reproduce an
#' official figure. Use `tidy_infosiga_labels()` on top of that when you are
#' doing your own analysis and want labels that group, sort and plot sensibly.
#'
#' @param data A data frame from [read_infosiga()] or [clean_infosiga()].
#' @param dataset Which dataset `data` corresponds to: `"sinistros"`,
#'   `"pessoas"` or `"veiculos"`. Determines which columns are rewritten.
#'
#' @return A [tibble][tibble::tibble] with the same rows as `data`. Columns are
#'   unchanged except as described in *Details*; `sinistros` additionally gains
#'   a `conservacao_codigo` column.
#'
#' @details
#' \subsection{Place names (sinistros, pessoas)}{
#' The source publishes `municipio` unaccented and upper case (`"SAO PAULO"`)
#' but `regiao_administrativa` with its accents intact, so neither can be
#' joined to other Brazilian data as published. Both take the official IBGE
#' spelling, matched on `cod_ibge` and never on the name. Nine municipalities
#' differ between the two sources: eight apostrophes that INFOSIGA renders as
#' spaces (`"SANTA BARBARA D OESTE"`), plus one genuine spelling difference,
#' IBGE's authoritative `"Sao Luiz do Paraitinga"` against INFOSIGA's
#' `"SAO LUIS DO PARAITINGA"`. See [infosiga_municipios].
#' }
#'
#' \subsection{Vehicle colour (veiculos)}{
#' `cor_veiculo` carries dozens of distinct values for roughly sixteen real
#' colours, because two upstream systems coexist in every year: an upper-case
#' stream (`"PRETA"`, `"BRANCA"`) and a title-case one with different gender
#' agreement (`"Preta"`, `"Branco"`). Note that `toupper()` alone will *not*
#' merge these. Values map onto a canonical set. Single-colour official liveries
#' (`"BRANCA (PADRAO PM)"`) fold into the base colour, two- and three-tone
#' values (`"CIN/VER/PRE"`) become `"Multicor"`, and camouflage becomes
#' `"Camuflada"`. Unrecognised values pass through unchanged, so a colour the
#' mapping does not know is never dropped.
#' }
#'
#' \subsection{Occupation (pessoas)}{
#' `profissao` is Title Cased, which merges the several hundred values that
#' differ from another value only by capitalisation, and `"NAO INFORMADA"` /
#' `"Nao informada"` become `NA`. Accents are **not** restored here and
#' occupations are **not** grouped semantically, because no authoritative
#' spelling list covers these free-text values. Expect near-duplicates to
#' remain.
#' }
#'
#' \subsection{Road maintenance (sinistros)}{
#' `conservacao` mixes two vocabularies: the name of the body that maintains
#' the road (`"PREFEITURA"`, `"NOVADUTRA"`) and bare route codes (`"10.03"`),
#' the latter covering tens of thousands of rows. The codes move into a new
#' `conservacao_codigo` column, so `conservacao` holds names only.
#'
#' Those names keep their source capitalisation, unlike every other column here.
#' Most are brands or acronyms (`"SPMAR"`, `"TEBE"`, `"CART"`, `"AUTOBAN"`,
#' `"DNIT"`), and Title Case would corrupt them into `"Spmar"` and `"Tebe"`.
#' }
#'
#' Every step is idempotent: calling `tidy_infosiga_labels()` on an
#' already-tidied dataset changes nothing.
#'
#' @seealso [clean_infosiga()] for the faithful processing this builds on, and
#'   [infosiga_municipios] for the municipality lookup.
#'
#' @examples
#' raw <- readr::read_delim(
#'   system.file("extdata", "veiculos_sample.csv", package = "infosigasp"),
#'   delim = ";", show_col_types = FALSE
#' )
#' tidied <- tidy_infosiga_labels(clean_infosiga(raw, "veiculos"), "veiculos")
#' sort(unique(tidied$cor_veiculo))
#' @export
tidy_infosiga_labels <- function(
  data,
  dataset = c(
    "sinistros",
    "pessoas",
    "veiculos"
  )
) {
  dataset <- match.arg(dataset)

  # Place names, matched on cod_ibge rather than on the name itself. Rows whose
  # code is missing or unknown keep whatever they already had.
  if ("cod_ibge" %in% names(data)) {
    # Qualified so R CMD check sees a binding for the lazy-loaded dataset.
    lookup <- infosigasp::infosiga_municipios
    idx <- match(data$cod_ibge, lookup$cod_ibge)
    ok <- !is.na(idx)
    for (col in intersect(
      c("municipio", "regiao_administrativa"),
      names(data)
    )) {
      data[[col]][ok] <- lookup[[col]][idx[ok]]
    }
  }

  if (dataset == "veiculos" && "cor_veiculo" %in% names(data)) {
    v <- data$cor_veiculo
    hit <- !is.na(v) & v %in% names(.cor_veiculo_map)
    v[hit] <- unname(.cor_veiculo_map[v[hit]])
    data$cor_veiculo <- v
  }

  if (dataset == "pessoas" && "profissao" %in% names(data)) {
    v <- data$profissao
    v[.matches_na_marker(v)] <- NA_character_
    data$profissao <- .pt_title_case(v)
  }

  if (dataset == "sinistros" && "conservacao" %in% names(data)) {
    v <- data$conservacao
    v[.matches_na_marker(v)] <- NA_character_
    is_code <- .is_route_code(v)
    code <- ifelse(is_code, v, NA_character_)
    v[is_code] <- NA_character_
    # On a second call the codes have already moved out, so `code` would be all
    # NA; fall back to the existing column to keep the split idempotent.
    if ("conservacao_codigo" %in% names(data)) {
      code <- ifelse(is.na(code), data$conservacao_codigo, code)
    }
    data$conservacao <- v
    data$conservacao_codigo <- code
    # Keep the new column immediately after the one it was split out of.
    before <- names(data)[seq_len(match("conservacao", names(data)))]
    rest <- setdiff(names(data), c(before, "conservacao_codigo"))
    data <- data[c(before, "conservacao_codigo", rest)]
  }

  tibble::as_tibble(data)
}
