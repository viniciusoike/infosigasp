# Download the INFOSIGA-SP data dictionary

Downloads the official INFOSIGA-SP data dictionary, a set of PDF
documents (one per dataset) describing every column and its accepted
values. The archive is saved to the cache and the extracted PDF paths
are returned. A searchable HTML transcription is available in the
[online data
dictionary](https://viniciusoike.github.io/infosigasp/articles/data-dictionary.html).

## Usage

``` r
dictionary_infosiga(dataset = NULL, refresh = FALSE, quiet = FALSE)
```

## Arguments

- dataset:

  Optional dataset whose dictionary should be returned: one of
  `"sinistros"`, `"pessoas"` or `"veiculos"`. If `NULL` (default),
  return all three dictionaries.

- refresh:

  Logical. If `TRUE`, download the dictionaries again before returning
  them. If `FALSE` (default), reuse the local copy when available.

- quiet:

  Logical. Suppress progress messages. Defaults to `FALSE`.

## Value

A character vector of paths to the extracted PDF files, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pdfs <- dictionary_infosiga()
# Open the dictionary for the crash-events dataset
browseURL(dictionary_infosiga("sinistros"))
} # }
```
