# Manage the infosigasp on-disk cache

INFOSIGA-SP ships its data as a single archive of roughly 120 MB
(uncompressed, over 700 MB). To avoid repeated downloads, infosigasp
stores the archive in a per-user cache directory and reuses it across
sessions. These functions inspect and manage that cache.

## Usage

``` r
infosiga_cache_dir()

infosiga_cache_list()

infosiga_cache_clear(confirm = interactive())
```

## Arguments

- confirm:

  Logical. If `TRUE` (the default in interactive sessions), ask for
  confirmation before deleting cached files. Set to `FALSE` to delete
  without prompting (e.g. in scripts).

## Value

- `infosiga_cache_dir()` returns the cache directory path (a string),
  creating it if necessary.

- `infosiga_cache_list()` returns a character vector of cached file
  paths (possibly empty).

- `infosiga_cache_clear()` invisibly returns the paths it removed.

## Details

The cache location defaults to the operating-system specific user cache
directory returned by
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html)
(`"infosigasp"`, `"cache"`). You can override it for the current session
with the `infosigasp.cache_dir` option, e.g.
`options(infosigasp.cache_dir = "~/my-cache")`, or permanently through
your `.Rprofile`.

## Examples

``` r
# Where does infosigasp cache its files?
infosiga_cache_dir()
#> [1] "/home/runner/.cache/R/infosigasp"

# What is currently cached?
infosiga_cache_list()
#> character(0)
```
