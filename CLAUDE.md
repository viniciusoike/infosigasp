# infosigasp

An R package providing a programmatic interface to INFOSIGA-SP (São Paulo State
Traffic Accident Information and Management System, maintained by DETRAN-SP). It
downloads and imports tidy data frames for three linked datasets: `sinistros`
(crash events), `pessoas` (victims), and `veiculos` (vehicles), from 2015 on.

## Design principles

- **Two-function public API.** Only `read_infosiga()` and
  `dictionary_infosiga()` are exported. Downloading, caching and transformations
  are implementation details reached through arguments to these functions.
- **Explicit processing modes.** `read_infosiga()` supports `"raw"` (all
  fields character with source representations preserved), `"typed"` (declared
  R classes without cleaning) and default `"clean"` modes. All cleaning logic
  lives in `.infosiga_clean()` and must stay **idempotent**.
- **Faithful layer, then harmonisation layer.** `.infosiga_clean()` fixes types
  and missing-value markers but never renames columns, recodes category labels
  or drops rows. Conservative label harmonisation belongs in
  `.infosiga_standardize()`, which users select with `standardize`. Analytical
  recoding and reshaping are outside the initial release scope.
- **Original column names are preserved** (Portuguese). Do not anglicise them;
  users cross-reference the official data dictionary (`dictionary_infosiga()`).
- **The cache is never poisoned by a bad download.** Downloads go to a tempfile,
  are validated (non-empty + ZIP magic bytes via `.infosiga_is_zip()`), and only
  then copied into the cache. A failed refresh leaves any existing archive intact.
- **Mirror fallback.** `infosigasp.zip_url` and `infosigasp.dictionary_url` may
  each be a vector of URLs tried in order. The default `zip_url` falls back to
  the `data-current` GitHub release, which
  `.github/workflows/refresh-data-mirror.yaml` re-uploads weekly whenever the
  DETRAN-SP archive hash changes. That tag rolls; never pin a dated one.
- **Refresh through the reader.** `read_infosiga(refresh = TRUE)` is the only
  public update path. The first interactive download asks for confirmation and
  reports the approximate 120 MB size; explicit refreshes do not prompt again.

## Conventions

- Code style: RStudio section headers (`# Section ----`), per the global
  CLAUDE.md. Internal helpers and constants are prefixed `.infosiga_`.
- User-facing messages, warnings, and errors go through **cli** (`cli_abort`,
  `cli_warn`, `cli_alert_*`) — never base `stop`/`warning`/`message`.
- Source/URL/spec constants live in `R/infosiga-specs.R`. Behaviour is tunable
  through `options()`: `infosigasp.cache_dir`, `infosigasp.zip_url` and
  `infosigasp.dictionary_url`.
- Data processing uses **dplyr and stringr**, not base R. `dplyr (>= 1.2.0)` is
  pinned because `.infosiga_clean()` and `.infosiga_standardize()` call
  `replace_values()` and `replace_when()`.
- Source files stay **pure ASCII**. Accented literals are built with
  `intToUtf8()` — see `.infosiga_factor_levels` in `R/clean.R`. The values are
  UTF-8, matching the decoded Latin-1 source.

## Data shipped with the package

- `R/sysdata.rda` holds `infosiga_municipios`, the 645-row `cod_ibge` to IBGE
  spelling lookup that the label layer joins against. Regenerate it with
  `data-raw/municipios.R`, which calls the IBGE API and
  `usethis::use_data(internal = TRUE)`.
- `inst/extdata/<dataset>_sample.csv` are 100-row UTF-8 extracts of the most
  recent period file, so examples and the vignette avoid the 120 MB download.

## Testing

- Tests must run **offline**. Network paths are exercised by pointing the URL
  options at `file://` URLs (see `test-download.R` and `test-dictionary.R`).
- The cache is redirected to a tempdir via the `infosigasp.cache_dir` option;
  use the `local_infosiga_fixture()` helper (`helper-cache.R`) to seed it with
  the fixture archive `tests/testthat/fixtures/dados_infosiga.zip`.
- Fixtures: `dados_infosiga.zip` (minimal data archive, two period files per
  dataset) and `dicionario.zip` (dummy dictionary PDFs). Both are Latin-1, like
  the source archive, while the `inst/extdata` samples are UTF-8; keep that
  split when regenerating either.
- `tests/testthat/_snaps/read.md` snapshots the cli output of
  `read_infosiga()`. Editing those messages means reviewing and accepting the
  snapshot with `testthat::snapshot_accept("read")`.
- testthat 3e. Prefer `withr::local_*` for option/tempdir cleanup.

## Useful commands

- `devtools::load_all()` / `devtools::test()` / `devtools::check()`
- `devtools::document()` after editing roxygen (regenerates `man/` + NAMESPACE)
- Rebuild the README from `README.Rmd` with `devtools::build_readme()`
- `data-raw/sample-data.R` regenerates the `inst/extdata` samples and the test
  fixtures; `data-raw/municipios.R` regenerates `R/sysdata.rda`. Both hit the
  network, so run them only after an upstream schema change.
