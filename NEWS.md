# infosigasp 0.1.0

Initial release.

* Added `read_infosiga()`, which downloads (with caching) and imports the three
  INFOSIGA-SP datasets (`sinistros`, `pessoas`, `veiculos`) as tibbles, handling
  the source encoding, decimal marks and date formats.
* Added `clean_infosiga()`, applied by default, which trims text, maps
  `"NAO DISPONIVEL"` to `NA`, makes the ordinal columns ordered factors, parses
  the `ano_mes_*` columns to first-of-month `Date`s, turns the `tp_sinistro_*`
  crash-type flags logical, fills blank `qtd_*` counts with `0` inside an
  otherwise-populated count block, casts `tempo_sinistro_obito` to integer,
  strips the spurious `".0"` on `numero_logradouro`, and voids coordinates
  outside the São Paulo state bounding box.
* Added `clean = FALSE` to `read_infosiga()` for the raw data as published.
* Added `tidy_infosiga_labels()`, an opt-in second pass that rewrites category
  labels for analysts who do not need the published categories verbatim: IBGE
  spellings for `municipio` and `regiao_administrativa`, merged `cor_veiculo`
  spellings, Title Cased `profissao`, and route codes split out of
  `conservacao` into a new `conservacao_codigo` column.
* Added the `infosiga_municipios` dataset, pairing the official IBGE name and
  the INFOSIGA-SP spelling of each São Paulo municipality, keyed by `cod_ibge`.
* Added `infosiga_download()` to pre-fetch the source archive, falling back to a
  GitHub-release mirror when the DETRAN-SP endpoint is unavailable; further
  mirrors go in the `infosigasp.zip_url` option. Responses are checked for the
  ZIP signature before being cached, so a portal serving an error page under a
  200 status falls through to the next mirror instead of poisoning the cache.
* Added a warning when `read_infosiga()` or `infosiga_download()` reuses a
  cached archive whose data are older than the `infosigasp.stale_days` option
  (30 days by default; set to `Inf` to disable), since DETRAN-SP refreshes the
  data monthly under the same file name. The age is that of the CSVs inside the
  archive rather than of the downloaded file, and the warning names the date
  they carry. It describes the local copy only: the package never asks
  DETRAN-SP whether a newer release exists.
* Added `infosiga_cache_dir()`, `infosiga_cache_list()` and
  `infosiga_cache_clear()` to manage the on-disk cache.
* Added `infosiga_datasets()`, which lists the available datasets and their
  keys, and `infosiga_dictionary()`, which downloads the official data
  dictionary. `infosigasp.dictionary_url` accepts a vector of mirrors tried in
  order, matching `infosigasp.zip_url`.
* Documented the coverage caveats of the source data in `?read_infosiga` and the
  getting-started vignette, chief among them that 2015–2018 covers fatal crashes
  only, so an unrestricted per-year count jumps roughly 20-fold in 2019.
* Added a package hex logo drawn from the major road network of the São Paulo
  Metropolitan Region in the INFOSIGA-SP dark blue (`data-raw/logo.R`).
