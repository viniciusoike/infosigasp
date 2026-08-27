test_that("place names are replaced with the official IBGE spelling", {
  raw <- tibble::tibble(
    # Sao Paulo, Ribeirao Preto, Sao Luiz do Paraitinga.
    cod_ibge = c("3550308", "3543402", "3550001"),
    municipio = c("SAO PAULO", "RIBEIRAO PRETO", "SAO LUIS DO PARAITINGA"),
    regiao_administrativa = c(
      "METROPOLITANA DE SAO PAULO",
      "RIBEIRAO PRETO",
      "SAO JOSE DOS CAMPOS"
    )
  )
  out <- .infosiga_standardize(raw, "sinistros")

  expect_identical(
    out$municipio,
    infosiga_municipios$municipio[
      match(raw$cod_ibge, infosiga_municipios$cod_ibge)
    ]
  )
  # The join is on cod_ibge, so the one municipality the two sources spell
  # differently still resolves.
  expect_identical(
    out$municipio[3],
    infosiga_municipios$municipio[
      infosiga_municipios$cod_ibge == "3550001"
    ]
  )
})

test_that("unknown or missing cod_ibge leaves place names untouched", {
  raw <- tibble::tibble(
    cod_ibge = c("9999999", NA),
    municipio = c("ALGURES", "OUTRO LUGAR")
  )
  out <- .infosiga_standardize(raw, "sinistros")
  expect_identical(out$municipio, c("ALGURES", "OUTRO LUGAR"))
})

test_that("place-name updates preserve duplicate observation keys", {
  raw <- tibble::tibble(
    cod_ibge = c("3550308", "3550308", "9999999", NA),
    municipio = c("SAO PAULO", "SAO PAULO", "ALGURES", "OUTRO LUGAR")
  )

  out <- .infosiga_standardize(raw, "sinistros")

  expect_identical(nrow(out), nrow(raw))
  expect_identical(out$municipio[1:2], c("São Paulo", "São Paulo"))
  expect_identical(out$municipio[3:4], raw$municipio[3:4])
})

test_that("cor_veiculo merges the case and gender duplicate spellings", {
  raw <- tibble::tibble(
    cor_veiculo = c(
      "PRETA",
      "Preta",
      "BRANCA",
      "Branco",
      "VERMELHA",
      "Vermelho"
    )
  )
  out <- .infosiga_standardize(raw, "veiculos")
  expect_identical(
    out$cor_veiculo,
    c("Preta", "Preta", "Branca", "Branca", "Vermelha", "Vermelha")
  )
})

test_that("cor_veiculo preserves detailed and multi-tone source values", {
  raw <- tibble::tibble(
    cor_veiculo = c(
      "BRANCA (PADRAO PM)",
      "CINZA BANDEIRANTE",
      "CIN/VER/PRE",
      "VERMELHA/PRETA",
      "CAMUFLADO URBANO"
    )
  )
  out <- .infosiga_standardize(raw, "veiculos")
  expect_identical(
    out$cor_veiculo,
    raw$cor_veiculo
  )
})

test_that("cor_veiculo passes unrecognised values through unchanged", {
  raw <- tibble::tibble(cor_veiculo = c("PRETA", "COR NOVA DO DETRAN", NA))
  out <- .infosiga_standardize(raw, "veiculos")
  expect_identical(out$cor_veiculo, c("Preta", "COR NOVA DO DETRAN", NA))
})

test_that("profissao is title cased with Portuguese connectives lowered", {
  raw <- tibble::tibble(
    profissao = c(
      "ADMINISTRADOR DE EMPRESAS",
      "DO LAR",
      "MOTO-BOY",
      "AUTONOMO(A)",
      "AEROVIARIO/AERONAUTA"
    )
  )
  out <- .infosiga_standardize(raw, "pessoas")
  expect_identical(
    out$profissao,
    c(
      "Administrador de Empresas",
      # A leading connective keeps its capital.
      "Do Lar",
      "Moto-Boy",
      "Autonomo(a)",
      "Aeroviario/Aeronauta"
    )
  )
})

test_that("profissao maps the source's other missing markers to NA", {
  raw <- tibble::tibble(
    profissao = c("NAO INFORMADA", "Nao informada", "PEDREIRO")
  )
  out <- .infosiga_standardize(raw, "pessoas")
  expect_identical(out$profissao, c(NA, NA, "Pedreiro"))
})

test_that("standardisation does not reshape conservacao", {
  raw <- tibble::tibble(
    conservacao = c("PREFEITURA", "10.03", "NOVADUTRA", "01.02", NA)
  )
  out <- .infosiga_standardize(raw, "sinistros")
  expect_identical(out, raw)
})

test_that(".infosiga_standardize is idempotent", {
  sinistros <- tibble::tibble(
    cod_ibge = c("3550308", "3543402"),
    municipio = c("SAO PAULO", "RIBEIRAO PRETO"),
    regiao_administrativa = c("METROPOLITANA DE SAO PAULO", "RIBEIRAO PRETO"),
    conservacao = c("PREFEITURA", "10.03")
  )
  pessoas <- tibble::tibble(profissao = c("MOTO-BOY", "NAO INFORMADA"))
  veiculos <- tibble::tibble(cor_veiculo = c("PRETA", "Branco", "CIN/VER/PRE"))

  for (case in list(
    list(sinistros, "sinistros"),
    list(pessoas, "pessoas"),
    list(veiculos, "veiculos")
  )) {
    once <- .infosiga_standardize(case[[1]], case[[2]])
    twice <- .infosiga_standardize(once, case[[2]])
    expect_identical(once, twice)
  }
})

test_that(".infosiga_standardize preserves dimensions and validates choices", {
  raw <- tibble::tibble(cor_veiculo = c("PRETA", "Branco", NA, "AZUL"))
  out <- .infosiga_standardize(raw, "veiculos")
  expect_identical(dim(out), dim(raw))
  expect_snapshot(.infosiga_standardize(raw, "carros"), error = TRUE)
  expect_snapshot(
    .infosiga_standardize(raw, "veiculos", "municipios"),
    error = TRUE
  )
  expect_snapshot(
    .infosiga_standardize(raw, "veiculos", "desconhecido"),
    error = TRUE
  )
  expect_snapshot(
    .infosiga_standardize(raw, "veiculos", c("all", "cores")),
    error = TRUE
  )
})

test_that("standardisations can be selected independently", {
  raw <- tibble::tibble(
    cod_ibge = "3550308",
    municipio = "SAO PAULO",
    profissao = "ADMINISTRADOR DE EMPRESAS"
  )

  municipios <- .infosiga_standardize(raw, "pessoas", "municipios")
  profissoes <- .infosiga_standardize(raw, "pessoas", "profissoes")

  expect_identical(municipios$municipio, "São Paulo")
  expect_identical(municipios$profissao, raw$profissao)
  expect_identical(profissoes$municipio, raw$municipio)
  expect_identical(profissoes$profissao, "Administrador de Empresas")
})

test_that("infosiga_municipios covers every municipality exactly once", {
  expect_identical(nrow(infosiga_municipios), 645L)
  expect_false(anyDuplicated(infosiga_municipios$cod_ibge) > 0)
  expect_false(anyNA(infosiga_municipios))
  expect_true(all(nchar(infosiga_municipios$cod_ibge) == 7))
  expect_length(unique(infosiga_municipios$regiao_administrativa), 16)
})
