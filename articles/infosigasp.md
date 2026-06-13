# Getting started with infosigasp

## Overview

[INFOSIGA-SP](https://infosiga.detran.sp.gov.br/) is the São Paulo State
Traffic Accident Information and Management System, maintained by
DETRAN-SP. It publishes, as open data, detailed records of every traffic
crash in the state of São Paulo from 2015 onward.

The `infosigasp` package wraps the download and import of those records.
It takes care of the things that make the raw files awkward to read
directly:

- the files are encoded in **Latin-1** (ISO-8859-1), not UTF-8;
- fields are separated by **semicolons** (`;`);
- decimal numbers (such as coordinates) use a **comma** decimal mark;
- dates are formatted **`DD/MM/YYYY`**;
- each dataset is split across **two files** (2015–2021 and 2022
  onward).

``` r

library(infosigasp)
```

## The three datasets

INFOSIGA-SP organises its data into three linked tables:

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

You can restrict the import to specific years with the `year` argument,
which filters on the year of the crash (`ano_sinistro`):

``` r

recent <- read_infosiga("sinistros", year = 2022:2025)
```

### Processed vs. raw data

By default
[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
returns a **processed** dataset (`clean = TRUE`). The processing is
light and lossless in spirit:

- dates are parsed to `Date` and times to `hms` (this happens in both
  modes);
- the `"NAO DISPONIVEL"` (“not available”) marker is replaced by `NA`;
- ordinal columns become **ordered factors**, so they sort and plot in
  their natural order instead of alphabetically:
  - `dia_da_semana`: `Domingo` \< … \< `Sábado` (the Brazilian week
    starts on Sunday);
  - `turno`: `MADRUGADA` \< `MANHA` \< `TARDE` \< `NOITE`;
  - `gravidade_lesao` (victims): `LEVE` \< `GRAVE` \< `FATAL`;
  - `faixa_etaria_demografica` / `faixa_etaria_legal`: age bands in
    order;
- `latitude`/`longitude` values outside the valid geographic range (a
  few mis-encoded source records) are set to `NA`.

``` r

sinistros <- read_infosiga("sinistros")
levels(sinistros$dia_da_semana)
```

Because `dia_da_semana` is an ordered factor, a weekday tabulation comes
out in calendar order rather than alphabetically:

``` r

table(sinistros$dia_da_semana)
```

If you would rather have the data exactly as published — every text
column as a character vector, with `"NAO DISPONIVEL"` preserved — pass
`clean = FALSE`:

``` r

raw <- read_infosiga("sinistros", clean = FALSE)
```

You can also apply the same processing to a raw import after the fact
with
[`clean_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/clean_infosiga.md):

``` r

processed <- clean_infosiga(raw, "sinistros")
```

### A peek at the structure without downloading

The package ships a small sample of each dataset so you can inspect the
columns without any network access:

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

## A short analysis

Once imported, the data are ordinary tibbles, so any tidyverse (or base
R) workflow applies. For example, counting traffic fatalities per year
from the victims dataset:

``` r

library(dplyr)

deaths_by_year <- read_infosiga("pessoas") |>
  filter(gravidade_lesao == "FATAL") |>
  count(ano_obito, name = "deaths") |>
  arrange(ano_obito)

deaths_by_year
```

Or fatalities broken down by the type of victim (driver, passenger,
pedestrian):

``` r

read_infosiga("pessoas") |>
  filter(gravidade_lesao == "FATAL") |>
  count(tipo_de_vitima, sort = TRUE)
```

Because `sinistros` carries latitude and longitude as numeric columns,
crash locations can be mapped directly or aggregated by municipality
(`municipio` / `cod_ibge`).

## Managing the cache

The download lives in an operating-system specific cache directory:

``` r

infosiga_cache_dir()
#> [1] "/home/runner/.cache/R/infosigasp"
infosiga_cache_list()
#> character(0)
```

The archive is refreshed monthly by DETRAN-SP. To pull the latest
version, force a re-download:

``` r

infosiga_download(overwrite = TRUE)
```

To reclaim disk space, clear the cache:

``` r

infosiga_cache_clear()
```

You can point the cache somewhere else for a session (or permanently via
your `.Rprofile`) with the `infosigasp.cache_dir` option:

``` r

options(infosigasp.cache_dir = "~/data/infosiga")
```

## The official data dictionary

INFOSIGA-SP distributes a field-by-field data dictionary (PDF, in
Portuguese).
[`infosiga_dictionary()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_dictionary.md)
downloads it and returns the paths to the extracted files:

``` r

pdfs <- infosiga_dictionary()
basename(pdfs)
```

## Citing the data

Data are published by DETRAN-SP under a Creative Commons Attribution 4.0
licence. When you publish results based on these data, please cite
INFOSIGA-SP / DETRAN-SP as the source:
<https://infosiga.detran.sp.gov.br/>.
