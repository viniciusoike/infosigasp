# Import an INFOSIGA-SP dataset

Downloads (if necessary) and imports one of the three INFOSIGA-SP
datasets as a tidy tibble. The source archive is cached locally, so the
first call triggers a download and subsequent calls read from disk.

## Usage

``` r
read_infosiga(
  dataset = c("sinistros", "pessoas", "veiculos"),
  year = NULL,
  download_if_missing = TRUE,
  quiet = FALSE,
  ...
)
```

## Arguments

- dataset:

  Which dataset to import. One of:

  `"sinistros"`

  :   Crash events (one row per event).

  `"pessoas"`

  :   Victims / people involved (one row per person).

  `"veiculos"`

  :   Vehicles involved (one row per vehicle).

- year:

  Optional integer vector used to filter rows by year of the crash
  (`ano_sinistro`). If `NULL` (default), all available years are
  returned. For example, `year = 2020:2023`.

- download_if_missing:

  Logical. If `TRUE` (default), download the archive when it is not
  already cached. If `FALSE` and the archive is missing, an informative
  error is raised.

- quiet:

  Logical. If `FALSE` (default), report progress.

- ...:

  Additional arguments passed to
  [`infosiga_download()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_download.md)
  (for example `overwrite = TRUE` to force a refresh).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per record. The columns keep the original INFOSIGA-SP names (in
Portuguese); see the package data dictionary via
[`infosiga_dictionary()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_dictionary.md).
The three datasets can be joined on `id_sinistro` (and `id_veiculo`,
where present).

## Details

Source files are encoded in Latin-1 (ISO-8859-1), use `;` as the field
separator, `,` as the decimal mark and `DD/MM/YYYY` dates.
`read_infosiga()` handles all of these and returns UTF-8 text, `Date`
columns and numeric coordinates. Each dataset is distributed across two
period files inside the archive (2015-2021 and 2022 onward); they are
read and row-bound transparently.

The imported data follow the source as closely as possible and are not
otherwise cleaned. A small fraction of rows in the source contain
data-quality issues (for example, an unescaped `;` inside a street name,
or mis-encoded `latitude`/`longitude` values); coordinates in particular
should be sanity-checked before mapping. Any value that cannot be parsed
to its declared column type is set to `NA` and recorded by
[`readr::problems()`](https://readr.tidyverse.org/reference/problems.html).

Empty fields are read as `NA`. Note that many categorical columns
instead use the literal value `"NAO DISPONIVEL"` ("not available") to
flag missing information; these are preserved as-is so the imported data
matches the source. The crash-type flag columns (`tp_sinistro_*`) hold
`"S"` when the flag applies and `NA` otherwise.

## See also

[`infosiga_download()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_download.md),
[`infosiga_cache_dir()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md),
[`infosiga_dictionary()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_dictionary.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# Import all crash events (downloads the archive on first use)
sinistros <- read_infosiga("sinistros")

# Only victims from 2022 and 2023
vitimas <- read_infosiga("pessoas", year = 2022:2023)
} # }

# A bundled sample (no download required) illustrates the structure:
sample_path <- system.file(
  "extdata", "sinistros_sample.csv",
  package = "infosigasp"
)
if (nzchar(sample_path)) head(readr::read_delim(sample_path, ";"))
#> Rows: 100 Columns: 48
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ";"
#> chr  (25): tipo_registro, data_sinistro, mes_sinistro, dia_sinistro, ano_mes...
#> dbl  (13): id_sinistro, ano_sinistro, numero_logradouro, cod_ibge, qtd_pedes...
#> num   (2): latitude, longitude
#> lgl   (7): qtd_bicicleta, qtd_caminhao, qtd_veic_outros, qtd_gravidade_ileso...
#> time  (1): hora_sinistro
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
#> # A tibble: 6 × 48
#>   id_sinistro tipo_registro data_sinistro ano_sinistro mes_sinistro dia_sinistro
#>         <dbl> <chr>         <chr>                <dbl> <chr>        <chr>       
#> 1     1265457 NOTIFICACAO   01/01/2022            2022 01           01          
#> 2     1301846 NOTIFICACAO   01/01/2022            2022 01           01          
#> 3     1352130 NOTIFICACAO   01/01/2022            2022 01           01          
#> 4     2279865 NOTIFICACAO   01/01/2022            2022 01           01          
#> 5     1444289 NOTIFICACAO   01/01/2022            2022 01           01          
#> 6     1322053 SINISTRO NAO… 01/01/2022            2022 01           01          
#> # ℹ 42 more variables: hora_sinistro <time>, ano_mes_sinistro <chr>,
#> #   dia_da_semana <chr>, turno <chr>, logradouro <chr>,
#> #   numero_logradouro <dbl>, tipo_via <chr>, tipo_local <chr>, latitude <dbl>,
#> #   longitude <dbl>, cod_ibge <dbl>, municipio <chr>,
#> #   regiao_administrativa <chr>, administracao <chr>, conservacao <chr>,
#> #   circunscricao <chr>, tp_sinistro_primario <chr>, qtd_pedestre <dbl>,
#> #   qtd_bicicleta <lgl>, qtd_motocicleta <dbl>, qtd_automovel <dbl>, …
```
