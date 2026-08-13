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
  crash-type flags logical, casts `tempo_sinistro_obito` to integer,
  strips the spurious `".0"` on `numero_logradouro`, and voids
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
  in the `infosigasp.zip_url` option.
- Added a warning when
  [`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
  or
  [`infosiga_download()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_download.md)
  reuses a cached archive older than the `infosigasp.stale_days` option
  (30 days by default; set to `Inf` to disable), since DETRAN-SP
  refreshes the data monthly under the same file name.
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
- Documented the coverage caveats of the source data in
  [`?read_infosiga`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
  and the getting-started vignette, chief among them that 2015–2018
  covers fatal crashes only, so an unrestricted per-year count jumps
  roughly 20-fold in 2019.
- Added a package hex logo drawn from the major road network of the São
  Paulo Metropolitan Region in the INFOSIGA-SP dark blue
  (`data-raw/logo.R`).
