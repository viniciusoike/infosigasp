# infosigasp

An R package providing a programmatic interface to INFOSIGA-SP (São Paulo State
Traffic Accident Information and Management System, maintained by DETRAN-SP). It
downloads and imports tidy data frames for three linked datasets: `sinistros`
(crash events), `pessoas` (victims), and `veiculos` (vehicles), from 2015 on.

## Design principles

- **Two-function public API.** Only `read_infosiga()` and
  `dictionary_infosiga()` are exported. Downloading, caching and transformations
  are implementation details reached through arguments to these functions.
- **Clean by default, raw on request.** `read_infosiga()` returns a processed
  tibble (`clean = TRUE`); `clean = FALSE` returns the data exactly as published.
  All cleaning logic lives in `.infosiga_clean()` and must stay **idempotent**.
- **Faithful layer, then opinionated layer.** `.infosiga_clean()` fixes types and
  missing-value markers but never renames columns, recodes category labels or
  drops rows. Anything that rewrites what the source says — IBGE municipality
  spellings, Title Case, merged categories — belongs in
  `.infosiga_tidy_labels()`, which users opt into with `labels = TRUE`.
- **Original column names are preserved** (Portuguese). Do not anglicise them;
  users cross-reference the official data dictionary (`dictionary_infosiga()`).
- **The cache is never poisoned by a bad download.** Downloads go to a tempfile,
  are validated (non-empty + ZIP magic bytes via `.infosiga_is_zip()`), and only
  then copied into the cache. A failed refresh leaves any existing archive intact.
- **Mirror fallback.** `infosigasp.zip_url` and `infosigasp.dictionary_url` may
  each be a vector of URLs tried in order.
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

## Testing

- Tests must run **offline**. Network paths are exercised by pointing the URL
  options at `file://` URLs (see `test-download.R` and `test-dictionary.R`).
- The cache is redirected to a tempdir via the `infosigasp.cache_dir` option;
  use the `local_infosiga_fixture()` helper (`helper-cache.R`) to seed it with
  the fixture archive `tests/testthat/fixtures/dados_infosiga.zip`.
- Fixtures: `dados_infosiga.zip` (minimal data archive, two period files per
  dataset) and `dicionario.zip` (dummy dictionary PDFs). Regenerate sample
  bundles and fixtures with `data-raw/sample-data.R`.
- testthat 3e. Prefer `withr::local_*` for option/tempdir cleanup.

## Useful commands

- `devtools::load_all()` / `devtools::test()` / `devtools::check()`
- `devtools::document()` after editing roxygen (regenerates `man/` + NAMESPACE)
- Rebuild the README from `README.Rmd` with `devtools::build_readme()`
