# Clean and process an INFOSIGA-SP dataset

Applies the standard processing that
[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
performs by default (`clean = TRUE`). Use this directly only when you
imported a dataset with `clean = FALSE` (the raw version) and want to
process it afterwards.

## Usage

``` r
clean_infosiga(data, dataset = c("sinistros", "pessoas", "veiculos"))
```

## Arguments

- data:

  A data frame imported with
  [`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
  (typically with `clean = FALSE`).

- dataset:

  Which dataset `data` corresponds to: `"sinistros"`, `"pessoas"` or
  `"veiculos"`. Determines which columns are processed.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with the
same columns as `data`, with the processing described in *Details*
applied.

## Details

The processing is deliberately light and lossless in spirit: it
standardises missing values and assigns meaningful order to the ordinal
columns, without renaming columns, recoding categories or dropping rows.

The following steps are applied:

1.  The literal `"NAO DISPONIVEL"` ("not available") marker is replaced
    by `NA` in every text column.

2.  Ordinal columns are converted to **ordered factors** with their
    natural order:

    - `dia_da_semana`: `Domingo` \< ... \< `Sabado` (the Brazilian week
      starts on Sunday).

    - `turno`: `MADRUGADA` \< `MANHA` \< `TARDE` \< `NOITE`.

    - `gravidade_lesao` (in `pessoas`): `LEVE` \< `GRAVE` \< `FATAL`.

    - `faixa_etaria_demografica`, `faixa_etaria_legal` (in `pessoas`):
      age bands in increasing order.

3.  In `sinistros`, `latitude` and `longitude` values that fall outside
    the valid geographic range (a small number of mis-encoded source
    records) are set to `NA`.

Nominal text columns (such as `municipio`, `tipo_via` or `sexo`) are
left as character vectors.

## See also

[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md),
which calls this function when `clean = TRUE`.

## Examples

``` r
# Process the bundled raw sample
raw <- readr::read_delim(
  system.file("extdata", "pessoas_sample.csv", package = "infosigasp"),
  delim = ";", show_col_types = FALSE
)
clean <- clean_infosiga(raw, "pessoas")
levels(clean$gravidade_lesao)
#> [1] "LEVE"  "GRAVE" "FATAL"
```
