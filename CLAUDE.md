# infosigasp

An R package providing a programmatic interface to INFOSIGA-SP (São Paulo State
Traffic Accident Information and Management System, maintained by DETRAN-SP). It
downloads and imports tidy data frames for three linked datasets: `sinistros`
(crash events), `pessoas` (victims), and `veiculos` (vehicles), from 2015 on.

## Design principles

- **Clean by default, raw on request.** `read_infosiga()` returns a processed
  tibble (`clean = TRUE`); `clean = FALSE` returns the data exactly as published.
  All cleaning logic lives in `clean_infosiga()` and must stay **idempotent** —
  calling it on already-cleaned data is a no-op (there is a test for this).
- **Original column names are preserved** (Portuguese). Do not anglicise them;
  users cross-reference the official data dictionary (`infosiga_dictionary()`).
- **The cache is never poisoned by a bad download.** Downloads go to a tempfile,
  are validated (non-empty + ZIP magic bytes via `.infosiga_is_zip()`), and only
  then copied into the cache. A failed refresh leaves any existing archive intact.
- **Mirror fallback + staleness.** `infosigasp.zip_url` may be a vector of URLs
  tried in order (official DETRAN-SP endpoint, then a GitHub-release snapshot).
  Reusing a cache older than `infosigasp.stale_days` (default 30) warns.

## Conventions

- Code style: RStudio section headers (`# Section ----`), per the global
  CLAUDE.md. Internal helpers and constants are prefixed `.infosiga_`.
- User-facing messages, warnings, and errors go through **cli** (`cli_abort`,
  `cli_warn`, `cli_alert_*`) — never base `stop`/`warning`/`message`.
- Source/URL/spec constants live in `R/infosiga-specs.R`. Behaviour is tunable
  through `options()`: `infosigasp.cache_dir`, `infosigasp.zip_url`,
  `infosigasp.dictionary_url`, `infosigasp.stale_days`.

## Testing

- Tests must run **offline**. Network paths are exercised by pointing the URL
  options at `file://` URLs (see `test-download.R`, `test-dictionary.R`).
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
