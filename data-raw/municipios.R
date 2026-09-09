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
library(dplyr)
library(sf)
# library(rvest)

# Preserve the state boundary stored in the same internal data file.
internal_data <- new.env(parent = emptyenv())
load("R/sysdata.rda", envir = internal_data)
spo_shape <- internal_data$spo_shape

# Official names and codes for the 645 municipalities of Sao Paulo state
# (UF code 35). IBGE ships them already correctly accented and cased.

fix_ibge_names <- function(dat) {
  col_names <- names(dat)

  fix_ibge_names <- \(x) {
    x |>
      # finds the second to last period and extract all text after
      stringr::str_extract("[^.]+\\.[^.]+$") |>
      # swaps the position of the elements (regiao.nome -> nome.regiao)
      stringr::str_replace("^([^.]+)\\.([^.]+)$", "\\2.\\1")
  }

  new_names <- dplyr::case_when(
    stringr::str_count(col_names, "\\.") > 1 ~ fix_ibge_names(col_names),
    .default = col_names
  )
  names(col_names) <- new_names

  dat <- dat |>
    dplyr::rename(dplyr::all_of(col_names)) |>
    janitor::clean_names()

  return(dat)
}

ibge <- jsonlite::fromJSON(
  "https://servicodados.ibge.gov.br/api/v1/localidades/estados/35/municipios",
  simplifyDataFrame = TRUE,
  flatten = TRUE
)

dim_ibge <- as_tibble(ibge)

dim_ibge <- dim_ibge |>
  select(-matches("regiao-intermediaria\\.UF")) |>
  fix_ibge_names()

# The source spellings, and INFOSIGA's own assignment of municipality to
# administrative region, come from the crash dataset itself.
sinistros <- read_infosiga("sinistros", processing = "clean", quiet = TRUE)

src <- sinistros |>
  distinct(cod_ibge, municipio, regiao_administrativa) |>
  arrange(cod_ibge)

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

# url_ras <- "https://repositorio.seade.gov.br/dataset/limites-e-regioes"

# dataset_list <- read_html(url_ras) |>
#   html_elements(xpath = "//section[@id='dataset-resources']/ul/li/a") |>
#   html_attrs()

# dataset_list <- purrr::map_df(dataset_list, ~ as_tibble(t(.x)))

# link <- dataset_list |>
#   filter(stringr::str_detect(title, "Região Administrativa$")) |>
#   pull(href)

# if (length(link) != 1) {
#   cli::cli_abort("Malformed URL")
# }

# dataset_dataframe_link <- paste0("https://repositorio.seade.gov.br", link)

# download_link <- read_html(dataset_dataframe_link) |>
#   html_element(xpath = "//a[@class='resource-url-analytics']") |>
#   html_text()

# download_link <- "https://repositorio.seade.gov.br/dataset/1866da41-fab1-42f1-a5eb-a435a41255ce/resource/91f71d41-91fe-4202-9102-da22164c3a85/download/regiao_administrativa.zip"

# download.file(
#   download_link,
#   destfile = here::here("data-raw/regioes_administrativas.zip")
# )

check_zip <- list.files(
  here::here("data-raw"),
  pattern = "regioes_administrativas\\.zip$"
)

if (length(check_zip) != 1) {
  cli::cli_abort("Zip file not found")
}

outdir <- here::here("data-raw", "spo_regioes_administrativas")

if (!dir.exists(outdir)) {
  dir.create(outdir)
  utils::unzip(here::here("data-raw", check_zip), list = TRUE)
} else {
  cli::cli_inform("Directory {.path {outdir}} already exists")
}

file_name <- list.files(outdir, pattern = "\\.shp$")

if (length(file_name) < 1) {
  cli::cli_abort("File {.file {file_name}} not found")
} else {
  spo_ras <- st_read(here::here(outdir, file_name), quiet = TRUE)
}

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
