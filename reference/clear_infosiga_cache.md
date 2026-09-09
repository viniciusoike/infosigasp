# Clear the INFOSIGA-SP cache

Removes package-managed cache entries. By default, only canonical
cleaned datasets are removed; the downloaded source archive is retained.
Files outside the package's managed cache paths are never touched.

## Usage

``` r
clear_infosiga_cache(processed = TRUE, source = FALSE, quiet = FALSE)
```

## Arguments

- processed:

  Logical. Remove all canonical cleaned datasets.

- source:

  Logical. Also remove the downloaded source ZIP archive.

- quiet:

  Logical. Suppress the completion message.

## Value

Invisibly, the paths that were selected for removal.

## See also

[`infosiga_cache_info()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache_info.md)
and
[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md).

## Examples

``` r
temporary_cache <- tempfile("infosigasp-example-")
old_options <- options(infosigasp.cache_dir = temporary_cache)
clear_infosiga_cache(quiet = TRUE)
options(old_options)
```
