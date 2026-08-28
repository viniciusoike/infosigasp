# Data dictionary

This article reproduces the official INFOSIGA-SP data dictionary
(**v1.5, 2026-06-16**), published by DETRAN-SP, for the three datasets
returned by
[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md):
`sinistros` (confirmed crashes and notifications), `pessoas` (victims)
and `veiculos` (vehicles). Field names, descriptions and allowed values
appear here verbatim;
[`dictionary_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/dictionary_infosiga.md)
downloads the original PDFs, which are in Portuguese.

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

## Sinistros (occurrence records)

One row per confirmed crash or notification, keyed by `id_sinistro` (48
variables).

## Pessoas (victims)

One row per person involved in a crash, keyed by `id_pessoa` and linked
to the other datasets by `id_sinistro` and `id_veiculo` (30 variables).

## Veículos (vehicles)

One row per vehicle involved in a crash, keyed by `id_veiculo` and
linked to the events by `id_sinistro` (12 variables).

## Source

DETRAN-SP, *Dicionário de dados* v1.5 (2026-06-16), distributed with the
INFOSIGA-SP open data at <https://infosiga.detran.sp.gov.br/>.
[`dictionary_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/dictionary_infosiga.md)
retrieves the official PDFs.

``` r

infosigasp::dictionary_infosiga()
```
