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
* `infosiga_download()` pre-fetches the source archive into a local cache.
* `infosiga_cache_dir()`, `infosiga_cache_list()` and `infosiga_cache_clear()`
  manage the on-disk cache.
* `infosiga_datasets()` lists the available datasets and their keys.
* `infosiga_dictionary()` downloads the official data dictionary.
