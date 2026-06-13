# Internal metadata: source URLs, dataset definitions and column specs ------

# Base URL of the DETRAN-SP download endpoint.
.infosiga_zip_url <- function() {
  getOption(
    "infosigasp.zip_url",
    "https://infosiga.detran.sp.gov.br/rest/painel/download/file/dados_infosiga.zip"
  )
}

# URL of the data dictionary archive (PDF files).
.infosiga_dictionary_url <- function() {
  getOption(
    "infosigasp.dictionary_url",
    paste0(
      "https://infosiga.detran.sp.gov.br/rest/painel/download/file/",
      "CGSV_Infosiga_SP_dicionario_dados.zip"
    )
  )
}

# File name of the cached source archive.
.infosiga_zip_name <- "dados_infosiga.zip"

# The valid dataset identifiers exposed to users.
.infosiga_datasets <- c("sinistros", "pessoas", "veiculos")

# Each dataset is shipped split across two period files inside the archive.
# `<dataset>_2015-2021.csv` and `<dataset>_2022-<current>.csv`. The trailing
# year changes over time, so members are matched by a regular expression.
.infosiga_members <- function(dataset) {
  paste0("^", dataset, "_\\d{4}-\\d{4}\\.csv$")
}

# Column type specifications, one per dataset. Encoding (latin1), decimal mark
# (",") and date format ("%d/%m/%Y") are supplied through the readr locale in
# read_infosiga(); here we only fix per-column classes. Identifier and code
# columns are kept as character to preserve leading zeros and avoid integer
# overflow, and to keep joins type-stable across datasets.
.infosiga_col_spec <- function(dataset) {
  dataset <- match.arg(dataset, .infosiga_datasets)
  c <- readr::col_character
  i <- readr::col_integer
  d <- function() readr::col_date(format = "%d/%m/%Y")
  n <- readr::col_double

  spec <- switch(
    dataset,
    sinistros = readr::cols(
      id_sinistro = c(), tipo_registro = c(),
      data_sinistro = d(), ano_sinistro = i(), mes_sinistro = i(),
      dia_sinistro = i(), hora_sinistro = readr::col_time(format = "%H:%M"),
      ano_mes_sinistro = c(), dia_da_semana = c(), turno = c(),
      logradouro = c(), numero_logradouro = c(), tipo_via = c(),
      tipo_local = c(), latitude = n(), longitude = n(), cod_ibge = c(),
      municipio = c(), regiao_administrativa = c(), administracao = c(),
      conservacao = c(), circunscricao = c(), tp_sinistro_primario = c(),
      qtd_pedestre = i(), qtd_bicicleta = i(), qtd_motocicleta = i(),
      qtd_automovel = i(), qtd_onibus = i(), qtd_caminhao = i(),
      qtd_veic_outros = i(), qtd_veic_nao_disponivel = i(),
      qtd_gravidade_fatal = i(), qtd_gravidade_grave = i(),
      qtd_gravidade_leve = i(), qtd_gravidade_ileso = i(),
      qtd_gravidade_nao_disponivel = i(),
      tp_sinistro_atropelamento = c(), tp_sinistro_colisao_frontal = c(),
      tp_sinistro_colisao_traseira = c(), tp_sinistro_colisao_lateral = c(),
      tp_sinistro_colisao_transversal = c(), tp_sinistro_colisao_outros = c(),
      tp_sinistro_choque = c(), tp_sinistro_capotamento = c(),
      tp_sinistro_engavetamento = c(), tp_sinistro_tombamento = c(),
      tp_sinistro_outros = c(), tp_sinistro_nao_disponivel = c()
    ),
    pessoas = readr::cols(
      id_sinistro = c(), id_veiculo = c(), cod_ibge = c(), municipio = c(),
      regiao_administrativa = c(), tipo_via = c(), tipo_veiculo_vitima = c(),
      sexo = c(), idade = i(), gravidade_lesao = c(), tipo_de_vitima = c(),
      faixa_etaria_demografica = c(), faixa_etaria_legal = c(),
      profissao = c(), grau_de_instrucao = c(), nacionalidade = c(),
      data_sinistro = d(), ano_sinistro = i(), mes_sinistro = i(),
      dia_sinistro = i(), ano_mes_sinistro = c(), data_obito = d(),
      ano_obito = i(), mes_obito = i(), dia_obito = i(), ano_mes_obito = c(),
      local_obito = c(), local_via = c(), tempo_sinistro_obito = c(),
      id_pessoa = c()
    ),
    veiculos = readr::cols(
      id_sinistro = c(), id_veiculo = c(), marca_modelo = c(),
      ano_fab = i(), ano_modelo = i(), cor_veiculo = c(), tipo_veiculo = c(),
      data_sinistro = d(), ano_sinistro = i(), mes_sinistro = i(),
      dia_sinistro = i(), ano_mes_sinistro = c()
    )
  )
  spec
}
