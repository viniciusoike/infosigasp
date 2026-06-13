# Download the INFOSIGA-SP data dictionary

Downloads the official INFOSIGA-SP data dictionary, a set of PDF
documents (one per dataset) describing every column and its accepted
values. The archive is saved to the cache and the extracted PDF paths
are returned.

## Usage

``` r
infosiga_dictionary(
  dest = file.path(infosiga_cache_dir(), "dictionary"),
  overwrite = FALSE,
  quiet = FALSE
)
```

## Arguments

- dest:

  Directory in which to extract the PDF files. Defaults to a
  `dictionary` sub-folder of
  [`infosiga_cache_dir()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md).

- overwrite:

  Logical. Re-download even if the dictionary archive is already cached.
  Defaults to `FALSE`.

- quiet:

  Logical. Suppress progress messages. Defaults to `FALSE`.

## Value

A character vector of paths to the extracted PDF files, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pdfs <- infosiga_dictionary()
# Open the dictionary for the crash-events dataset
browseURL(grep("sinistros", pdfs, value = TRUE))
} # }
```
