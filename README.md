
<!-- README.md is generated from README.Rmd. Please edit that file -->

# infosigasp <a href="https://viniciusoike.github.io/infosigasp/"><img src="man/figures/logo.png" align="right" height="120" alt="infosigasp website" /></a>

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/viniciusoike/infosigasp/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/viniciusoike/infosigasp/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`infosigasp` provides a clean, programmatic interface to the open data
published by **INFOSIGA-SP**, the São Paulo State Traffic Accident
Information and Management System maintained by **DETRAN-SP** (the São
Paulo State Department of Motor Vehicles).

The package downloads the official data archive, handles its quirks
(Latin-1 encoding, semicolon separators, comma decimal marks,
`DD/MM/YYYY` dates) and returns tidy tibbles ready for analysis. It
covers every traffic crash recorded in the state of São Paulo from
**2015 onward**.

## Installation

You can install the development version from GitHub with:

``` r
# install.packages("pak")
pak::pak("viniciusoike/infosigasp")
```

## Datasets

INFOSIGA-SP publishes three linked datasets:

``` r
library(infosigasp)
infosiga_datasets()
#> # A tibble: 3 x 4
#>   dataset   description                                              grain keys 
#>   <chr>     <chr>                                                    <chr> <chr>
#> 1 sinistros Traffic crash events recorded in the state of Sao Paulo. one ~ id_s~
#> 2 pessoas   People (victims) involved in traffic crashes.            one ~ id_p~
#> 3 veiculos  Vehicles involved in traffic crashes.                    one ~ id_v~
```

The datasets can be joined through `id_sinistro` (and `id_veiculo`,
where present).

## Usage

The first call downloads the source archive (~120 MB) into a local
cache; later calls read straight from disk.

``` r
library(infosigasp)

# Crash events (one row per event)
sinistros <- read_infosiga("sinistros")

# Victims, restricted to recent years
vitimas <- read_infosiga("pessoas", year = 2022:2025)

# Vehicles involved
veiculos <- read_infosiga("veiculos")
```

### Managing the cache

``` r
infosiga_cache_dir()      # where files are stored
infosiga_cache_list()     # what is currently cached
infosiga_download(overwrite = TRUE)  # force a refresh after a monthly update
infosiga_cache_clear()    # delete cached files
```

### Data dictionary

The official field-by-field documentation (PDF, in Portuguese) can be
fetched with:

``` r
infosiga_dictionary()
```

## Example

A small fatality summary by year, using the victims dataset:

``` r
library(dplyr)

read_infosiga("pessoas") |>
  filter(gravidade_lesao == "FATAL") |>
  count(ano_obito, name = "deaths") |>
  arrange(ano_obito)
```

## Data source and licence

Data are published by DETRAN-SP under a [Creative Commons Attribution
4.0](https://creativecommons.org/licenses/by/4.0/) licence at
<https://infosiga.detran.sp.gov.br/>. When using the data, please cite
INFOSIGA-SP / DETRAN-SP as the source.

This package is released under the MIT licence and is **not** affiliated
with or endorsed by DETRAN-SP or the Government of the State of São
Paulo.
