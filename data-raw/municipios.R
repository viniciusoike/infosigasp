# Build the cod_ibge -> municipality lookup shipped as `infosiga_municipios`.
#
# INFOSIGA-SP publishes municipality names in unaccented upper case
# ("SAO PAULO") but administrative-region names accented ("SÃO PAULO"), so
# neither column can be joined to other Brazilian sources as published. This
# script pairs the source spellings with the official IBGE names.
#
# Run it after an upstream schema change, or when IBGE revises the municipality
# list. It needs network access and the cached INFOSIGA archive.

library(infosigasp)

# Official names and codes for the 645 municipalities of Sao Paulo state
# (UF code 35). IBGE ships them already correctly accented and cased.
ibge <- jsonlite::fromJSON(
  "https://servicodados.ibge.gov.br/api/v1/localidades/estados/35/municipios"
)

# The source spellings, and INFOSIGA's own assignment of municipality to
# administrative region, come from the crash dataset itself.
sinistros <- read_infosiga("sinistros", processing = "clean", quiet = TRUE)
src <- unique(sinistros[c("cod_ibge", "municipio", "regiao_administrativa")])
src <- src[order(src$cod_ibge), ]

stopifnot(
  !anyDuplicated(src$cod_ibge),
  nrow(src) == nrow(ibge),
  setequal(src$cod_ibge, as.character(ibge$id))
)

# Fold accented upper case to plain ASCII upper case, so the keys below stay
# readable and match regardless of how the source spells its accents.
# chartr() rather than iconv(..., "ASCII//TRANSLIT"): the latter is
# locale- and platform-dependent (macOS renders "SÃO" as "S~AO").
fold <- function(x) {
  chartr(
    "ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ",
    "AAAAAEEEEIIIIOOOOOUUUUCN",
    toupper(x)
  )
}

# Title-case the 16 administrative regions by hand: Portuguese keeps
# connectives ("de", "do", "dos") in lower case, which no general-purpose
# title-case function gets right. Keys are the ASCII fold of the source
# spelling; values use \u escapes so this file stays pure ASCII.
regioes <- c(
  "ARACATUBA" = "Araçatuba",
  "BAIXADA SANTISTA" = "Baixada Santista",
  "BARRETOS" = "Barretos",
  "BAURU" = "Bauru",
  "CAMPINAS" = "Campinas",
  "CENTRAL" = "Central",
  "FRANCA" = "Franca",
  "ITAPEVA" = "Itapeva",
  "MARILIA" = "Marília",
  "METROPOLITANA DE SAO PAULO" = "Metropolitana de São Paulo",
  "PRESIDENTE PRUDENTE" = "Presidente Prudente",
  "REGISTRO" = "Registro",
  "RIBEIRAO PRETO" = "Ribeirão Preto",
  "SAO JOSE DO RIO PRETO" = "São José do Rio Preto",
  "SAO JOSE DOS CAMPOS" = "São José dos Campos",
  "SOROCABA" = "Sorocaba"
)

stopifnot(setequal(fold(src$regiao_administrativa), names(regioes)))

ord <- match(src$cod_ibge, as.character(ibge$id))

infosiga_municipios <- tibble::tibble(
  cod_ibge = src$cod_ibge,
  municipio = ibge$nome[ord],
  municipio_infosiga = src$municipio,
  regiao_administrativa = unname(regioes[fold(src$regiao_administrativa)]),
  regiao_administrativa_infosiga = src$regiao_administrativa
)

# Sanity-check the pairing. The two sources agree on the folded name for all
# but nine municipalities, and those nine are why this lookup exists: joining
# INFOSIGA to IBGE *by name* silently drops them. Eight are apostrophes that
# INFOSIGA renders as spaces ("SANTA BARBARA D OESTE" for "Santa Bárbara
# d'Oeste"); the ninth is a real spelling difference, "São Luiz do Paraitinga"
# (IBGE, authoritative) against "SAO LUIS DO PARAITINGA". Everything here is
# keyed on cod_ibge, so none of it affects the join.
known_spelling_diffs <- "3550001"

mismatch <- with(
  infosiga_municipios,
  gsub("'", " ", fold(municipio), fixed = TRUE) != municipio_infosiga
)

stopifnot(
  nrow(infosiga_municipios) == 645,
  !anyNA(infosiga_municipios),
  setequal(infosiga_municipios$cod_ibge[mismatch], known_spelling_diffs)
)

usethis::use_data(infosiga_municipios, internal = TRUE, overwrite = TRUE)
