# infosigasp 0.2.0

* Coordinate validation now uses the São Paulo state boundary with a 2 km buffer instead of its rectangular bounding box.
* Documented important changes in source-data coverage and definitions, including that 2015--2018 covers fatal crashes only and that `sinistros` includes unconfirmed notifications.
* Missing `qtd_*` counts now remain `NA` during cleaning because a blank source value does not establish a zero count.
* Simplified the public data API around `read_infosiga()` and `dictionary_infosiga()`; download, update, data-listing, cleaning and label-standardization helpers are internal implementation details. (#20)
* `clear_infosiga_cache()` and `infosiga_cache_info()` remove processed cache entries and report their disk use while keeping operations within the package-managed user cache.
* `dictionary_infosiga()` replaces `infosiga_dictionary()`, downloads the official PDF dictionaries for all datasets or a selected dataset, and links to the searchable online data dictionary. (#20)
* `read_infosiga()` caches the canonical clean result by source checksum and cleaning-schema version, reuses it before applying optional standardizations, and removes obsolete processed artifacts. Set `cache = FALSE` to bypass the processed cache.
* `read_infosiga()` now supports explicit `"raw"`, `"typed"` and `"clean"` processing modes, with `"clean"` remaining the default. (#22)
* `read_infosiga()` now supports selective label standardization through `standardize = "municipios"`, `"cores"`, `"profissoes"` or `"all"`, while preserving source categories that cannot be harmonized safely. (#22)
* `read_infosiga()` now preserves unexpected categorical, flag and integer representations and emits a warning instead of silently coercing them. (#22)
* `read_infosiga()` no longer accepts the non-pushdown `year` argument; filter `ano_sinistro` after import when a year subset is needed. (#20)

# infosigasp 0.1.0

Initial release.

* Added `read_infosiga()`, which downloads (with caching) and imports the three INFOSIGA-SP datasets (`sinistros`, `pessoas` and `veiculos`) as tidy tibbles, handling the source encoding, decimal marks and date formats.
* Added `clean_infosiga()`, applied by default, which trims text, maps `"NAO DISPONIVEL"` to `NA`, makes ordinal columns ordered factors, parses the `ano_mes_*` columns to first-of-month `Date`s, turns the `tp_sinistro_*` crash-type flags logical, fills blank `qtd_*` counts with `0` inside an otherwise-populated count block, casts `tempo_sinistro_obito` to integer, strips the spurious `".0"` on `numero_logradouro`, and voids coordinates outside the São Paulo state bounding box.
* Added `clean = FALSE` to `read_infosiga()` for the raw data as published.
* Added `tidy_infosiga_labels()`, an opt-in second pass that rewrites category labels for analysts who do not need the published categories verbatim: IBGE spellings for `municipio` and `regiao_administrativa`, merged `cor_veiculo` spellings, Title Cased `profissao`, and route codes split out of `conservacao` into a new `conservacao_codigo` column.
* Added the `infosiga_municipios` dataset, pairing the official IBGE name and the INFOSIGA-SP spelling of each São Paulo municipality, keyed by `cod_ibge`.
* Added `infosiga_download()` to pre-fetch the source archive, falling back to a GitHub-release mirror when the DETRAN-SP endpoint is unavailable; further mirrors go in the `infosigasp.zip_url` option. Responses are checked for the ZIP signature before being cached, so a portal serving an error page under a 200 status falls through to the next mirror instead of poisoning the cache.
* Added a warning when `read_infosiga()` or `infosiga_download()` reuses a cached archive whose data are older than the `infosigasp.stale_days` option (30 days by default; set to `Inf` to disable), since DETRAN-SP refreshes the data monthly under the same file name. The age is that of the CSVs inside the archive rather than of the downloaded file, and the warning names the date they carry. It describes the local copy only; use `infosiga_check_update()` to compare it against a remote source.
* Added `infosiga_check_update()`, which reports whether the archive published on the package mirror is newer than the cached copy. It reads a small manifest describing the mirrored archive rather than the archive itself. A weekly GitHub Actions job re-fetches the official archive and republishes the mirror whenever its contents change, so the mirror can trail DETRAN-SP by up to a week. `infosigasp.manifest_url` accepts a vector of mirrors tried in order, matching `infosigasp.zip_url`.
* Added `infosiga_cache_dir()`, `infosiga_cache_list()` and `infosiga_cache_clear()` to manage the on-disk cache.
* Added `infosiga_datasets()`, which lists the available datasets and their keys, and `infosiga_dictionary()`, which downloads the official data dictionary. `infosigasp.dictionary_url` accepts a vector of mirrors tried in order, matching `infosigasp.zip_url`.
* Added a package hex logo drawn from the major road network of the São Paulo Metropolitan Region in the INFOSIGA-SP dark blue (`data-raw/logo.R`).
