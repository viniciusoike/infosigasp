# Tidy the category labels of an INFOSIGA-SP dataset

An **opt-in** companion to
[`clean_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/clean_infosiga.md)
that rewrites category labels into a consistent, presentation-ready
form: Title Case, accents restored where an authoritative spelling
exists, duplicate categories merged, and the source's assorted "not
informed" strings mapped to `NA`.

## Usage

``` r
tidy_infosiga_labels(data, dataset = c("sinistros", "pessoas", "veiculos"))
```

## Arguments

- data:

  A data frame from
  [`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
  or
  [`clean_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/clean_infosiga.md).

- dataset:

  Which dataset `data` corresponds to: `"sinistros"`, `"pessoas"` or
  `"veiculos"`. Determines which columns are rewritten.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with the
same rows as `data`. Columns are unchanged except as described in
*Details*; `sinistros` additionally gains a `conservacao_codigo` column.

## Details

It stays separate from
[`clean_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/clean_infosiga.md),
which never touches labels. Use
[`clean_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/clean_infosiga.md)
(or `read_infosiga(clean = TRUE)`) when you need categories exactly as
DETRAN-SP publishes them, for example to reproduce an official figure.
Use `tidy_infosiga_labels()` on top of that when you are doing your own
analysis and want labels that group, sort and plot sensibly.

### Place names (sinistros, pessoas)

The source publishes `municipio` unaccented and upper case
(`"SAO PAULO"`) but `regiao_administrativa` with its accents intact, so
neither can be joined to other Brazilian data as published. Both take
the official IBGE spelling, matched on `cod_ibge` and never on the name.
Nine municipalities differ between the two sources: eight apostrophes
that INFOSIGA renders as spaces (`"SANTA BARBARA D OESTE"`), plus one
genuine spelling difference, IBGE's authoritative
`"Sao Luiz do Paraitinga"` against INFOSIGA's
`"SAO LUIS DO PARAITINGA"`. See
[infosiga_municipios](https://viniciusoike.github.io/infosigasp/reference/infosiga_municipios.md).

### Vehicle colour (veiculos)

`cor_veiculo` carries dozens of distinct values for roughly sixteen real
colours, because two upstream systems coexist in every year: an
upper-case stream (`"PRETA"`, `"BRANCA"`) and a title-case one with
different gender agreement (`"Preta"`, `"Branco"`). Note that
[`toupper()`](https://rdrr.io/r/base/chartr.html) alone will *not* merge
these. Values map onto a canonical set. Single-colour official liveries
(`"BRANCA (PADRAO PM)"`) fold into the base colour, two- and three-tone
values (`"CIN/VER/PRE"`) become `"Multicor"`, and camouflage becomes
`"Camuflada"`. Unrecognised values pass through unchanged, so a colour
the mapping does not know is never dropped.

### Occupation (pessoas)

`profissao` is Title Cased, which merges the several hundred values that
differ from another value only by capitalisation, and `"NAO INFORMADA"`
/ `"Nao informada"` become `NA`. Accents are **not** restored here and
occupations are **not** grouped semantically, because no authoritative
spelling list covers these free-text values. Expect near-duplicates to
remain.

### Road maintenance (sinistros)

`conservacao` mixes two vocabularies: the name of the body that
maintains the road (`"PREFEITURA"`, `"NOVADUTRA"`) and bare route codes
(`"10.03"`), the latter covering tens of thousands of rows. The codes
move into a new `conservacao_codigo` column, so `conservacao` holds
names only.

Those names keep their source capitalisation, unlike every other column
here. Most are brands or acronyms (`"SPMAR"`, `"TEBE"`, `"CART"`,
`"AUTOBAN"`, `"DNIT"`), and Title Case would corrupt them into `"Spmar"`
and `"Tebe"`.

Every step is idempotent: calling `tidy_infosiga_labels()` on an
already-tidied dataset changes nothing.

## See also

[`clean_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/clean_infosiga.md)
for the faithful processing this builds on, and
[infosiga_municipios](https://viniciusoike.github.io/infosigasp/reference/infosiga_municipios.md)
for the municipality lookup.

## Examples

``` r
raw <- readr::read_delim(
  system.file("extdata", "veiculos_sample.csv", package = "infosigasp"),
  delim = ";", show_col_types = FALSE
)
tidied <- tidy_infosiga_labels(clean_infosiga(raw, "veiculos"), "veiculos")
sort(unique(tidied$cor_veiculo))
#>  [1] "Azul"     "Bege"     "Branca"   "Cinza"    "Laranja"  "Marrom"  
#>  [7] "Prata"    "Preta"    "Verde"    "Vermelha"
```
