# Data dictionary

This article transcribes the official INFOSIGA-SP data dictionary
(**v1.5, 2026-06-16**), published by DETRAN-SP, for the three datasets
returned by
[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md):
`sinistros` (confirmed crashes and notifications), `pessoas` (victims)
and `veiculos` (vehicles). Field names, descriptions and category codes
remain in Portuguese. The transcription only normalizes line breaks,
list separators and minor punctuation;
[`dictionary_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/dictionary_infosiga.md)
downloads the original PDFs.

A [Brazilian Portuguese
version](https://viniciusoike.github.io/infosigasp/articles/data-dictionary-pt.md)
of this article is also available.

Three notes on reading the tables.

- **Click a row** (or the arrow) to expand the storage format, the
  source of the field, the full list of allowed values and any
  additional notes.
- The **Type** and **Nulls** columns describe the source schema, not
  necessarily the returned R classes. `processing = "raw"` returns every
  field as character; `"typed"` parses the documented classes; and the
  default `"clean"` mode adds missing-value, factor and flag
  conversions. See
  [`?read_infosiga`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
  for the full pipeline.
- In the *Source* field, **PC**, **PM** and **PRF** stand for Polícia
  Civil, Polícia Militar and Polícia Rodoviária Federal; **DETRAN-SP**
  marks fields derived by the Infosiga system itself.

## Sinistros (crash records)

One row per confirmed crash or notification, keyed by `id_sinistro` (48
variables).

## Pessoas (victims)

One row per person involved in a crash, keyed by `id_pessoa` and linked
to the other datasets by `id_sinistro` and `id_veiculo` (30 variables).

## Veículos (vehicles)

One row per vehicle involved in a crash, identified by `id_sinistro` and
`id_veiculo` (12 variables).

## Known inconsistencies in the source

The official PDFs contain a few internal inconsistencies. In the
`pessoas` dictionary, the format for `ano_mes_sinistro` and
`ano_mes_obito` is printed as `mm/aaaa`, but the permitted ranges and
published data use `aaaa/mm`. Some year ranges say “greater than 2022”
although the corresponding files include 2022. The observations for
`ano_fab` and `ano_modelo` also print their inequalities in reverse. The
tables above preserve the official wording. The package’s type
specifications follow the values found in the data files; identifiers
and `numero_logradouro` remain character vectors to avoid losing
information.

## Source

DETRAN-SP, *Dicionário de dados* v1.5 (2026-06-16), distributed with the
INFOSIGA-SP open data at <https://infosiga.detran.sp.gov.br/>.
[`dictionary_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/dictionary_infosiga.md)
retrieves the official PDFs.

``` r

infosigasp::dictionary_infosiga()
```
