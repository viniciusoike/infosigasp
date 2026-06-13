# List the available INFOSIGA-SP datasets

Returns a small tibble describing the datasets that
[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
can import, including their grain (what one row represents) and key
columns.

## Usage

``` r
infosiga_datasets()
```

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns `dataset`, `description`, `grain` and `keys`.

## Examples

``` r
infosiga_datasets()
#> # A tibble: 3 × 4
#>   dataset   description                                              grain keys 
#>   <chr>     <chr>                                                    <chr> <chr>
#> 1 sinistros Traffic crash events recorded in the state of Sao Paulo. one … id_s…
#> 2 pessoas   People (victims) involved in traffic crashes.            one … id_p…
#> 3 veiculos  Vehicles involved in traffic crashes.                    one … id_v…
```
