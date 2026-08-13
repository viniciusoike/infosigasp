# Changelog

## infosigasp 0.1.0

Initial release.

- Added
  [`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md),
  which downloads (with caching) and imports the three INFOSIGA-SP
  datasets (`sinistros`, `pessoas`, `veiculos`) as tibbles, handling the
  source encoding, decimal marks and date formats.
- Added
  [`clean_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/clean_infosiga.md),
  applied by default, which trims text, maps `"NAO DISPONIVEL"` to `NA`,
  makes the ordinal columns ordered factors, parses the `ano_mes_*`
  columns to first-of-month `Date`s, turns the `tp_sinistro_*`
  crash-type flags logical, fills blank `qtd_*` counts with `0` inside
  an otherwise-populated count block, casts `tempo_sinistro_obito` to
  integer, strips the spurious `".0"` on `numero_logradouro`, and voids
  coordinates outside the São Paulo state bounding box.
- Added `clean = FALSE` to
  [`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
  for the raw data as published.
- Added
  [`tidy_infosiga_labels()`](https://viniciusoike.github.io/infosigasp/reference/tidy_infosiga_labels.md),
  an opt-in second pass that rewrites category labels for analysts who
  do not need the published categories verbatim: IBGE spellings for
  `municipio` and `regiao_administrativa`, merged `cor_veiculo`
  spellings, Title Cased `profissao`, and route codes split out of
  `conservacao` into a new `conservacao_codigo` column.
- Added the `infosiga_municipios` dataset, pairing the official IBGE
  name and the INFOSIGA-SP spelling of each São Paulo municipality,
  keyed by `cod_ibge`.
- Added
  [`infosiga_download()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_download.md)
  to pre-fetch the source archive, falling back to a GitHub-release
  mirror when the DETRAN-SP endpoint is unavailable; further mirrors go
  in the `infosigasp.zip_url` option. Responses are checked for the ZIP
  signature before being cached, so a portal serving an error page under
  a 200 status falls through to the next mirror instead of poisoning the
  cache.
- Added a warning when
  [`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
  or
  [`infosiga_download()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_download.md)
  reuses a cached archive whose data are older than the
  `infosigasp.stale_days` option (30 days by default; set to `Inf` to
  disable), since DETRAN-SP refreshes the data monthly under the same
  file name. The age is that of the CSVs inside the archive rather than
  of the downloaded file, and the warning names the date they carry. It
  describes the local copy only; use
  [`infosiga_check_update()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_check_update.md)
  to compare it against a remote source.
- Added
  [`infosiga_check_update()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_check_update.md),
  which reports whether the archive published on the package mirror is
  newer than the cached copy. It reads a small manifest describing the
  mirrored archive rather than the archive itself. A weekly GitHub
  Actions job re-fetches the official archive and republishes the mirror
  whenever its contents change, so the mirror can trail DETRAN-SP by up
  to a week. `infosigasp.manifest_url` accepts a vector of mirrors tried
  in order, matching `infosigasp.zip_url`.
- Added
  [`infosiga_cache_dir()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md),
  [`infosiga_cache_list()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md)
  and
  [`infosiga_cache_clear()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md)
  to manage the on-disk cache.
- Added
  [`infosiga_datasets()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_datasets.md),
  which lists the available datasets and their keys, and
  [`infosiga_dictionary()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_dictionary.md),
  which downloads the official data dictionary.
  `infosigasp.dictionary_url` accepts a vector of mirrors tried in
  order, matching `infosigasp.zip_url`.
- Documented the coverage caveats of the source data in
  [`?read_infosiga`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
  and the getting-started vignette, chief among them that 2015–2018
  covers fatal crashes only, so an unrestricted per-year count jumps
  roughly 20-fold in 2019.
- Added a package hex logo drawn from the major road network of the São
  Paulo Metropolitan Region in the INFOSIGA-SP dark blue
  (`data-raw/logo.R`).
