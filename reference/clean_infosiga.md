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

The processing standardises missing values, fixes source formatting
artefacts and assigns meaningful types to columns whose published
representation is inconvenient (ordinal text, binary flags, year-month
strings). It never renames columns, recodes category labels or drops
rows.

`clean_infosiga()` applies the following steps, in order. Every step is
idempotent, so calling the function again on an already-processed
dataset changes nothing.

1.  **Whitespace.** Trims leading and trailing whitespace from every
    text column. Some source fields are space-padded to a fixed width
    (for example `nacionalidade` is published as `"BRASILEIRA "`);
    without trimming, comparisons, grouping and joins on those columns
    silently fail.

2.  **Missing values.** Replaces the literal `"NAO DISPONIVEL"` ("not
    available") marker with `NA` in every text column. Trimming runs
    first, so space-padded markers are also caught.

3.  **Ordered factors.** Ordinal columns become **ordered factors** in
    their natural order.

    - `dia_da_semana`: `Domingo` \< ... \< `Sabado` (the Brazilian week
      starts on Sunday).

    - `turno`: `MADRUGADA` \< `MANHA` \< `TARDE` \< `NOITE`.

    - `gravidade_lesao` (in `pessoas`): `LEVE` \< `GRAVE` \< `FATAL`.

    - `faixa_etaria_demografica`, `faixa_etaria_legal` (in `pessoas`):
      age bands in increasing order.

4.  **Year-month dates.** Parses the year-month columns
    (`ano_mes_sinistro`, `ano_mes_obito`), published as `"YYYY/MM"`
    strings, to first-of-month `Date` values, matching the `Date` class
    already used for the full-date columns.

5.  **Crash-type flags** (`sinistros`). The binary `tp_sinistro_*`
    columns become **logical** (`TRUE` / `FALSE`). They mark whether a
    crash involved a given event type and are published as `"S"` (yes)
    or empty (no). The categorical `tp_sinistro_primario` (the primary
    crash type, e.g. `"COLISAO"`) is *not* a flag and stays text.
    `tp_sinistro_colisao_traseira` is empty for every record in the
    source and therefore becomes uniformly `FALSE`. That is an
    unpopulated upstream field, not evidence that no rear-end collisions
    occurred. A crash may also set several flags at once, so the flags
    do not partition the data.

6.  **Count columns** (`sinistros`). The `qtd_*` columns form two
    independent blocks: vehicle counts (`qtd_pedestre`, `qtd_automovel`,
    ...) and victim-severity counts (`qtd_gravidade_*`). A blank entry
    inside a block that is otherwise filled in means *zero* and becomes
    `0L`. When a record carries no breakdown at all, the whole block is
    blank; those blanks are genuinely "not recorded" and stay `NA`. The
    two blocks are handled separately because many records carry one but
    not the other.

7.  **Days to death** (`pessoas`). `tempo_sinistro_obito`, the number of
    days between the crash and the victim's death (published as a
    numeric string), becomes **integer**.

8.  **Street numbers and kilometre markers** (`sinistros`).
    `numero_logradouro` carries a house number on urban streets but a
    **kilometre marker** on highways, where a fractional part is
    meaningful (`"0.25"` is km 250 m, not a malformed house number).
    Genuine decimals are common on `ESTRADAS E RODOVIAS` rows and rare
    on `VIAS URBANAS` ones. Only a trailing `".0"` from the source
    export is stripped (`"193.0"` -\> `"193"`); any other decimal part
    survives. The column stays character because the two meanings are
    not comparable on a single numeric scale.

9.  **Coordinates** (`sinistros`). Validates `latitude`/`longitude` as a
    pair against the bounding box of the state of Sao Paulo. Points
    outside the box, which are mis-encoded values and `(0, 0)` "null
    island" placeholders, have both coordinates set to `NA`. This
    affects a few percent of records and drops no rows. Use
    `clean = FALSE` if you need the raw coordinates.

Nominal text columns (such as `municipio`, `tipo_via` or `sexo`) stay
character vectors. Well-typed numeric columns, notably `idade` (the
victim's age, in `pessoas`), pass through unchanged and are *not*
range-checked. Missing ages are `NA` and ages of `0` (infants) are kept.
The package enforces no bound on `idade`, so validate it yourself if
your analysis is sensitive to outliers.

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
