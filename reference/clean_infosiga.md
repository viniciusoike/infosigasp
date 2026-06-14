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

The processing is deliberately light: it standardises missing values,
fixes source formatting artefacts and assigns meaningful types to
columns whose published representation is inconvenient (ordinal text,
binary flags, year-month strings). It never renames columns, recodes
category labels or drops rows, so the result stays a faithful,
analysis-ready view of the source.

The following steps are applied, in order. Every step is idempotent, so
`clean_infosiga()` can be called again on an already-processed dataset
without changing it.

1.  **Whitespace.** Leading and trailing whitespace is trimmed from
    every text column. Some source fields are space-padded to a fixed
    width (for example `nacionalidade` is published as `"BRASILEIRA "`);
    without trimming, comparisons, grouping and joins on those columns
    silently fail.

2.  **Missing values.** The literal `"NAO DISPONIVEL"` ("not available")
    marker is replaced by `NA` in every text column. Trimming happens
    first so that space-padded markers are also caught.

3.  **Ordered factors.** Ordinal columns are converted to **ordered
    factors** with their natural order:

    - `dia_da_semana`: `Domingo` \< ... \< `Sabado` (the Brazilian week
      starts on Sunday).

    - `turno`: `MADRUGADA` \< `MANHA` \< `TARDE` \< `NOITE`.

    - `gravidade_lesao` (in `pessoas`): `LEVE` \< `GRAVE` \< `FATAL`.

    - `faixa_etaria_demografica`, `faixa_etaria_legal` (in `pessoas`):
      age bands in increasing order.

4.  **Year-month dates.** Year-month columns (`ano_mes_sinistro`,
    `ano_mes_obito`), published as `"YYYY/MM"` strings, are parsed to
    first-of-month `Date` values, matching the `Date` class already used
    for the full-date columns.

5.  **Crash-type flags** (`sinistros`). The binary `tp_sinistro_*`
    columns – which mark whether a crash involved a given event type and
    are published as `"S"` (yes) or empty (no) – become **logical**
    (`TRUE` / `FALSE`). The categorical `tp_sinistro_primario` (the
    primary crash type, e.g. `"COLISAO"`) is *not* a flag and is left as
    text.

6.  **Days to death** (`pessoas`). `tempo_sinistro_obito`, the number of
    days between the crash and the victim's death (published as a
    numeric string), becomes **integer**.

7.  **Street numbers** (`sinistros`). `numero_logradouro` is kept as
    text (house numbers may contain letters), but a spurious trailing
    `".0"` from the source export (`"193.0"`) is stripped to `"193"`.

8.  **Coordinates** (`sinistros`). `latitude`/`longitude` are validated
    as a pair against the bounding box of the state of Sao Paulo. Points
    outside the box – mis-encoded values and `(0, 0)` "null island"
    placeholders – have both coordinates set to `NA`. This affects
    roughly 7% of records; no rows are dropped. Use `clean = FALSE` if
    you need the raw coordinates.

Nominal text columns (such as `municipio`, `tipo_via` or `sexo`) are
left as character vectors. Numeric columns that are already well typed –
notably `idade` (the victim's age, in `pessoas`) – are passed through
unchanged and are *not* range-checked: missing ages are `NA`, and ages
of `0` (infants) are kept. In the current upstream data `idade` ranges
from 0 to about 102, but the package does not enforce any bound, so
validate it yourself if your analysis is sensitive to outliers.

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
