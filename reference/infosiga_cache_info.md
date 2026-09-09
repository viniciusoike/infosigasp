# Inspect the INFOSIGA-SP cache

Lists the source archive and canonical cleaned datasets currently stored
in the package cache. Merely inspecting the cache does not create any
files or directories.

## Usage

``` r
infosiga_cache_info()
```

## Value

A tibble with the cache entry type, dataset, absolute path, size in MiB
and modification time. Returns an empty tibble when the cache is empty.

## See also

[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
and
[`clear_infosiga_cache()`](https://viniciusoike.github.io/infosigasp/reference/clear_infosiga_cache.md).

## Examples

``` r
infosiga_cache_info()
#> # A tibble: 0 × 5
#> # ℹ 5 variables: type <chr>, dataset <chr>, path <chr>, size_mb <dbl>,
#> #   modified <dttm>
```
