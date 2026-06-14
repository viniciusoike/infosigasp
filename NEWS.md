# infosigasp 0.1.0

* Initial release.
* New package hex logo: the major road network of the São Paulo Metropolitan
  Region in the INFOSIGA-SP dark blue (`data-raw/logo.R`).
* `read_infosiga()` downloads (with caching) and imports the three INFOSIGA-SP
  datasets (`sinistros`, `pessoas`, `veiculos`) as tidy tibbles, handling the
  source encoding, decimal marks and date formats.
* `read_infosiga()` returns a processed dataset by default (`clean = TRUE`):
  text columns are whitespace-trimmed (the source pads some fields to a fixed
  width), `"NAO DISPONIVEL"` becomes `NA`, ordinal columns (`dia_da_semana`,
  `turno`, `gravidade_lesao`, age bands) become ordered factors, the
  `ano_mes_*` year-month columns are parsed to first-of-month `Date`s, the
  binary `tp_sinistro_*` crash-type flags become logical, `tempo_sinistro_obito`
  becomes integer, the spurious `".0"` on `numero_logradouro` is stripped, and
  coordinates outside the São Paulo state bounding box are dropped. Use
  `clean = FALSE` for the raw data as published, or `clean_infosiga()` to
  process a raw import afterwards.
* `infosiga_download()` pre-fetches the source archive into a local cache. It
  tries the official DETRAN-SP endpoint first and falls back to a GitHub-release
  mirror if it is unavailable; additional mirrors can be supplied via the
  `infosigasp.zip_url` option (a character vector tried in order).
* `read_infosiga()` and `infosiga_download()` warn when a cached archive is
  reused that is older than the `infosigasp.stale_days` option (30 days by
  default; set to `Inf` to disable), since DETRAN-SP refreshes the data monthly
  under the same file name.
* `infosiga_cache_dir()`, `infosiga_cache_list()` and `infosiga_cache_clear()`
  manage the on-disk cache.
* `infosiga_datasets()` lists the available datasets and their keys.
* `infosiga_dictionary()` downloads the official data dictionary.
