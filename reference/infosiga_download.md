# Download the INFOSIGA-SP source archive

Downloads the consolidated INFOSIGA-SP data archive
(`dados_infosiga.zip`) from DETRAN-SP into the local cache. Most users
do not need to call this directly:
[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
downloads the archive on demand. Use this function when you want to
pre-fetch the data (for example, before going offline) or to force a
refresh.

## Usage

``` r
infosiga_download(overwrite = FALSE, quiet = FALSE, timeout = 3600)
```

## Arguments

- overwrite:

  Logical. If `FALSE` (default) and the archive is already cached, the
  existing file is kept and returned. Set to `TRUE` to download again
  and replace it.

- quiet:

  Logical. If `FALSE` (default), report progress with informative
  messages.

- timeout:

  Download timeout in seconds. The archive is large (around 120 MB), so
  the default temporarily raises
  [`options()`](https://rdrr.io/r/base/options.html)`$timeout` to
  `3600`. Pass a larger value on slow connections.

## Value

The path to the cached archive, invisibly.

## Details

The archive is updated monthly by DETRAN-SP and accumulates all records
from 2015 onward. The download URL can be overridden with the
`infosigasp.zip_url` option, which is mainly useful for testing.

## See also

[`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
to import the data, and
[`infosiga_cache_dir()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md)
to locate the cache.

## Examples

``` r
if (FALSE) { # \dontrun{
# Pre-fetch the archive into the cache
infosiga_download()

# Force a refresh after a monthly update
infosiga_download(overwrite = TRUE)
} # }
```
