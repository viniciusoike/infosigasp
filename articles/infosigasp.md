# Getting started with infosigasp

## Overview

[INFOSIGA-SP](https://infosiga.detran.sp.gov.br/) is the São Paulo State
Traffic Accident Information and Management System, maintained by
DETRAN-SP. It publishes, as open data, detailed records of every traffic
crash in the state of São Paulo from 2015 onward.

`infosigasp` downloads and imports those records. It handles what makes
the raw files awkward to read directly.

- The files use **Latin-1** (ISO-8859-1), not UTF-8.
- **Semicolons** (`;`) separate the fields.
- Decimal numbers, such as coordinates, use a **comma** decimal mark.
- Dates follow **`DD/MM/YYYY`**.
- Each dataset spans **two files** (2015–2021 and 2022 onward).

``` r

library(infosigasp)
```

## The three datasets

INFOSIGA-SP organises its data into three linked tables.

``` r

infosiga_datasets()
#> # A tibble: 3 × 4
#>   dataset   description                                              grain keys 
#>   <chr>     <chr>                                                    <chr> <chr>
#> 1 sinistros Traffic crash events recorded in the state of Sao Paulo. one … id_s…
#> 2 pessoas   People (victims) involved in traffic crashes.            one … id_p…
#> 3 veiculos  Vehicles involved in traffic crashes.                    one … id_v…
```

- **`sinistros`** — crash *events*. One row per recorded event, with the
  date, time, location (including latitude/longitude), road attributes
  and a breakdown of how many vehicles and victims were involved, by
  type and severity.
- **`pessoas`** — *people* (victims). One row per person involved, with
  demographic attributes, injury severity and, for fatalities, the date
  and place of death.
- **`veiculos`** — *vehicles*. One row per vehicle involved, with
  make/model, manufacturing and model years, colour and type.

All three share the `id_sinistro` key, so they can be joined together;
`pessoas` and `veiculos` additionally share `id_veiculo`.

## Reading data

The main entry point is
[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md).
The first call downloads the source archive (about 120 MB) into a
per-user cache; subsequent calls read from that cache, so you only pay
the download cost once.

``` r

sinistros <- read_infosiga("sinistros")
sinistros
```

The `year` argument restricts the import to specific years, filtering on
the year of the crash (`ano_sinistro`).

``` r

recent <- read_infosiga("sinistros", year = 2022:2025)
```

### Processed vs. raw data

By default
[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
returns a **processed** dataset (`clean = TRUE`). The processing never
renames columns, recodes category labels or drops rows. It only fixes
types and source artefacts. The full, ordered list of steps lives in
[`?clean_infosiga`](https://viniciusoike.github.io/infosigasp/reference/clean_infosiga.md);
the main ones are below.

- **Dates and times.** Full dates are parsed to `Date` and times to
  `hms` (in both modes), and the `ano_mes_*` year-month columns
  (published as `"YYYY/MM"`) become first-of-month `Date` values.
- **Whitespace.** Text columns lose their leading and trailing
  whitespace. The source pads some fields to a fixed width
  (`nacionalidade` ships as `"BRASILEIRA "`); untrimmed, those values
  break grouping and joins.
- **Missing values.** The `"NAO DISPONIVEL"` (“not available”) marker
  becomes `NA` (trimming runs first, so space-padded markers are
  caught).
- **Ordered factors.** Ordinal columns sort and plot in their natural
  order instead of alphabetically.
  - `dia_da_semana`: `Domingo` \< … \< `Sábado` (the Brazilian week
    starts on Sunday);
  - `turno`: `MADRUGADA` \< `MANHA` \< `TARDE` \< `NOITE`;
  - `gravidade_lesao` (victims): `LEVE` \< `GRAVE` \< `FATAL`;
  - `faixa_etaria_demografica` / `faixa_etaria_legal`: age bands in
    order.
- **Crash-type flags.** The binary `tp_sinistro_*` columns (`"S"` /
  empty) become **logical**, so you can
  [`sum()`](https://rdrr.io/r/base/sum.html) or filter them directly.
  The categorical `tp_sinistro_primario` stays text.
- **Numeric strings.** `tempo_sinistro_obito` (days from crash to death)
  becomes **integer**, and `numero_logradouro` loses the spurious
  trailing `".0"` the export appends (`"193.0"`).
- **Coordinates.** `latitude`/`longitude` outside the São Paulo state
  bounding box become `NA` as a pair. These are mis-encoded values and
  `(0, 0)` placeholders, a few percent of records. No rows are dropped;
  pass `clean = FALSE` for the raw coordinates.

``` r

sinistros <- read_infosiga("sinistros")
levels(sinistros$dia_da_semana)
```

`dia_da_semana` is an ordered factor, so a weekday tabulation comes out
in calendar order rather than alphabetically.

``` r

table(sinistros$dia_da_semana)
```

Pass `clean = FALSE` if you would rather have the data exactly as
published, with every text column a character vector and
`"NAO DISPONIVEL"` and the source’s whitespace padding preserved
verbatim.

``` r

raw <- read_infosiga("sinistros", clean = FALSE)
```

[`clean_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/clean_infosiga.md)
applies the same processing to a raw import after the fact.

``` r

processed <- clean_infosiga(raw, "sinistros")
```

### Tidying the category labels

[`clean_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/clean_infosiga.md)
fixes types and source artefacts but never touches category *labels*, so
that anyone reproducing an official DETRAN-SP figure gets exactly the
categories DETRAN-SP publishes. Those labels are, however, genuinely
messy. For your own analysis, run the opt-in second pass
[`tidy_infosiga_labels()`](https://viniciusoike.github.io/infosigasp/reference/tidy_infosiga_labels.md).

``` r

veiculos <- read_infosiga("veiculos") |>
  tidy_infosiga_labels("veiculos")

sort(table(veiculos$cor_veiculo), decreasing = TRUE)
```

Vehicle colour is the clearest case. The source carries dozens of
distinct values for **about sixteen real colours**, because two upstream
systems coexist in every year, one upper-case and one title-cased, and
the two disagree on gender agreement.

| source values                            | tidied     |
|------------------------------------------|------------|
| `PRETA`, `Preta`                         | `Preta`    |
| `BRANCA`, `Branco`, `BRANCA (PADRAO PM)` | `Branca`   |
| `VERMELHA`, `Vermelho`                   | `Vermelha` |
| `CIN/VER/PRE`, `BRANCA/VERMELHA`         | `Multicor` |

Note that [`toupper()`](https://rdrr.io/r/base/chartr.html) alone will
not merge `Branca` and `Branco`.

The remaining changes are listed below.

- **Place names.** The source publishes `municipio` unaccented
  (`"SAO PAULO"`) while `regiao_administrativa` keeps its accents, so
  neither joins to other Brazilian data as published. Both take the
  official IBGE spelling.
- **`profissao`** is Title Cased, which merges the several hundred
  values that differ from another only by capitalisation, and the stray
  `"NAO INFORMADA"` markers become `NA`.
- **`conservacao`** mixes the name of the maintaining body
  (`"PREFEITURA"`) with bare route codes (`"10.03"`); the codes move to
  a new `conservacao_codigo` column.

Two limits are worth naming. `profissao` keeps its unaccented spelling
and its occupations stay ungrouped, because no authoritative list covers
these free-text values. `conservacao` names keep their source
capitalisation, because most are brand acronyms (`SPMAR`, `TEBE`,
`CART`) that Title Case would corrupt into `Spmar` and `Tebe`.

### Joining to other Brazilian data

The `infosiga_municipios` lookup ships with the package and maps
`cod_ibge` to both spellings of each of the 645 municipalities.

``` r

head(infosiga_municipios, 4)
#> # A tibble: 4 × 5
#>   cod_ibge municipio      municipio_infosiga regiao_administrativa
#>   <chr>    <chr>          <chr>              <chr>                
#> 1 3500105  Adamantina     ADAMANTINA         Presidente Prudente  
#> 2 3500204  Adolfo         ADOLFO             São José do Rio Preto
#> 3 3500303  Aguaí          AGUAI              Campinas             
#> 4 3500402  Águas da Prata AGUAS DA PRATA     Campinas             
#> # ℹ 1 more variable: regiao_administrativa_infosiga <chr>
```

Always join on `cod_ibge`, never on the name. IBGE and INFOSIGA-SP spell
nine municipalities differently. Eight contain an apostrophe that
INFOSIGA-SP renders as a space (`"Santa Bárbara d'Oeste"` against
`"SANTA BARBARA D OESTE"`), and IBGE’s `"São Luiz do Paraitinga"`
appears as `"SAO LUIS DO PARAITINGA"`. A name join loses all nine
silently. `cod_ibge` is also the standard Brazilian municipality key, so
it joins INFOSIGA-SP to census and population data. Those are the
denominators that turn crash counts into crash *rates*.

### Inspecting the structure without downloading

The package ships a small sample of each dataset so you can inspect the
columns without any network access.

``` r

sample_path <- system.file("extdata", "sinistros_sample.csv", package = "infosigasp")
sample <- readr::read_delim(
  sample_path,
  delim = ";",
  show_col_types = FALSE
)
dim(sample)
#> [1] 100  48
names(sample)
#>  [1] "id_sinistro"                     "tipo_registro"                  
#>  [3] "data_sinistro"                   "ano_sinistro"                   
#>  [5] "mes_sinistro"                    "dia_sinistro"                   
#>  [7] "hora_sinistro"                   "ano_mes_sinistro"               
#>  [9] "dia_da_semana"                   "turno"                          
#> [11] "logradouro"                      "numero_logradouro"              
#> [13] "tipo_via"                        "tipo_local"                     
#> [15] "latitude"                        "longitude"                      
#> [17] "cod_ibge"                        "municipio"                      
#> [19] "regiao_administrativa"           "administracao"                  
#> [21] "conservacao"                     "circunscricao"                  
#> [23] "tp_sinistro_primario"            "qtd_pedestre"                   
#> [25] "qtd_bicicleta"                   "qtd_motocicleta"                
#> [27] "qtd_automovel"                   "qtd_onibus"                     
#> [29] "qtd_caminhao"                    "qtd_veic_outros"                
#> [31] "qtd_veic_nao_disponivel"         "qtd_gravidade_fatal"            
#> [33] "qtd_gravidade_grave"             "qtd_gravidade_leve"             
#> [35] "qtd_gravidade_ileso"             "qtd_gravidade_nao_disponivel"   
#> [37] "tp_sinistro_atropelamento"       "tp_sinistro_colisao_frontal"    
#> [39] "tp_sinistro_colisao_traseira"    "tp_sinistro_colisao_lateral"    
#> [41] "tp_sinistro_colisao_transversal" "tp_sinistro_colisao_outros"     
#> [43] "tp_sinistro_choque"              "tp_sinistro_capotamento"        
#> [45] "tp_sinistro_engavetamento"       "tp_sinistro_tombamento"         
#> [47] "tp_sinistro_outros"              "tp_sinistro_nao_disponivel"
```

## Coverage and caveats

INFOSIGA-SP publishes one continuous series from 2015 onward, but what
the series *contains* has changed over time. These are properties of the
source data, not import artefacts, so `infosigasp` reports them rather
than correcting them. Several will quietly invalidate an analysis that
looks perfectly reasonable.
[`?read_infosiga`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
carries the full list; the two below catch people out most often.

### 2015–2018 covers fatal crashes only

Non-fatal records begin in **2019**. Before that, every row is a fatal
crash. Counting crashes per year over the whole series therefore
produces a roughly 20-fold jump in 2019 that reflects only the expansion
of data collection.

| year | fatal crashes | non-fatal crashes |
|------|---------------|-------------------|
| 2015 | 5,942         | 0                 |
| 2018 | 4,869         | 0                 |
| 2019 | 4,804         | 116,412           |
| 2023 | 5,166         | 135,329           |

Those counts come from a 2026 release and shift as DETRAN-SP revises the
data. The break in 2019 does not move. The same break appears in
`pessoas`, where the `LEVE` and `GRAVE` injury levels simply do not
occur before 2019.

So for any trend that reaches back before 2019, **restrict to
fatalities**.

``` r

library(dplyr)

read_infosiga("sinistros") |>
  filter(tipo_registro == "SINISTRO FATAL") |>
  count(ano_sinistro)
```

Otherwise, start the series in 2019 by passing a `year` range to
[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md).

### A third of `sinistros` rows are notifications

`tipo_registro` distinguishes confirmed crashes from `"NOTIFICACAO"`, a
reported event not yet confirmed as a crash. Notifications are about a
third of all rows, so treating every row as a crash overstates the total
considerably.

``` r

read_infosiga("sinistros") |>
  count(tipo_registro, sort = TRUE)
```

DETRAN-SP reclassifies records as it validates them, so the newest
months carry an unusually high share of notifications. The last month or
two of any release is also incomplete. Drop the tail of the series
before reading anything into a recent trend.

### Smaller caveats

- **`tempo_sinistro_obito` is capped at 30 days**, the standard
  convention for attributing a death to a crash. Fatality counts here
  are 30-day counts.
- **The `qtd_*` vehicle columns disagree with the `veiculos` row count**
  for a small share of crashes. Pick one definition and say which. (The
  `qtd_gravidade_*` columns *do* match `pessoas` exactly.)
- **Coordinate availability varies by year.** It is highest through the
  middle of the series and lower at both ends, so a mapped subset is not
  a uniform time sample.
- **About a third of crashes have no `pessoas` row.** Use a left join to
  keep them.

## A short analysis

The imported data are ordinary tibbles, so any tidyverse (or base R)
workflow applies. Here is a count of traffic fatalities per year from
the victims dataset.

``` r

library(dplyr)

deaths_by_year <- read_infosiga("pessoas") |>
  filter(gravidade_lesao == "FATAL") |>
  count(ano_obito, name = "deaths") |>
  arrange(ano_obito)

deaths_by_year
```

That series is safe to read across all years because it counts only
fatalities, the one thing collected consistently since 2015.

Fatalities also break down by the type of victim (driver, passenger,
pedestrian).

``` r

read_infosiga("pessoas") |>
  filter(gravidade_lesao == "FATAL") |>
  count(tipo_de_vitima, sort = TRUE)
```

`sinistros` carries latitude and longitude as numeric columns, so you
can map crash locations directly or aggregate them by municipality
(`municipio` / `cod_ibge`).

## Managing the cache

The download lives in an operating-system specific cache directory.

``` r

infosiga_cache_dir()
#> [1] "/home/runner/.cache/R/infosigasp"
infosiga_cache_list()
#> character(0)
```

DETRAN-SP refreshes the archive monthly.
[`infosiga_check_update()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_check_update.md)
compares your cached copy against the mirror the package publishes,
which a weekly job re-fetches from DETRAN-SP, so it answers whether a
newer archive exists without downloading one.

``` r

infosiga_check_update()
```

Force a re-download to pull the latest version.

``` r

infosiga_download(overwrite = TRUE)
```

Clear the cache to reclaim disk space.

``` r

infosiga_cache_clear()
```

You can point the cache somewhere else for a session (or permanently via
your `.Rprofile`) with the `infosigasp.cache_dir` option.

``` r

options(infosigasp.cache_dir = "~/data/infosiga")
```

## The official data dictionary

INFOSIGA-SP distributes a field-by-field data dictionary (PDF, in
Portuguese).
[`infosiga_dictionary()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_dictionary.md)
downloads it and returns the paths to the extracted files.

``` r

pdfs <- infosiga_dictionary()
basename(pdfs)
```

## Citing the data

DETRAN-SP publishes the data under a Creative Commons Attribution 4.0
licence. When you publish results based on these data, please cite
INFOSIGA-SP / DETRAN-SP as the source,
<https://infosiga.detran.sp.gov.br/>.
