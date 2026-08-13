# Check the cached archive against the package mirror

Reports whether the INFOSIGA-SP archive published on the package mirror
is newer than your cached copy. Unlike the staleness warning raised by
[`infosiga_download()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_download.md),
which only measures how old the local copy is, this function asks a
remote source what it holds. It reads a small manifest (a few hundred
bytes) rather than the ~120 MB archive.

## Usage

``` r
infosiga_check_update(quiet = FALSE, timeout = 60)
```

## Arguments

- quiet:

  Logical. If `FALSE` (default), report the comparison with informative
  messages.

- timeout:

  Timeout in seconds for fetching the manifest.

## Value

A one-row [tibble](https://tibble.tidyverse.org/reference/tibble.html),
invisibly, with columns `update_available`, `identical_to_mirror`,
`local_date`, `mirror_date`, `mirror_published`, `mirror_size` and
`mirror_url`. The two date columns carry the timestamp of the CSVs
inside each archive, `mirror_published` is when the mirror was
refreshed, and `mirror_size` is in bytes.

## Details

The comparison is against the mirror, not against DETRAN-SP. A GitHub
Actions workflow re-fetches the official archive weekly and republishes
it whenever its contents change, so the mirror can trail the portal by
up to a week. `update_available = FALSE` therefore means the mirror
holds nothing newer than your copy, and
[`infosiga_download()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_download.md)
may still find fresher data at DETRAN-SP, which it tries first.

Both archives are identified by the MD5 sum of the ZIP file and by the
timestamp its members carry. A cached copy that matches the mirror's
checksum is reported as identical. One that differs but is not older, as
happens when you download from DETRAN-SP before the weekly refresh runs,
is reported as no update available.

The manifest URL can be overridden with the `infosigasp.manifest_url`
option, which may be a character vector of mirrors tried in order.

## See also

[`infosiga_download()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_download.md)
to fetch the archive, and
[infosiga_cache](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md)
to manage the local copy.

## Examples

``` r
if (FALSE) { # \dontrun{
infosiga_check_update()

# Refresh only when the mirror has something newer
if (infosiga_check_update(quiet = TRUE)$update_available) {
  infosiga_download(overwrite = TRUE)
}
} # }
```
