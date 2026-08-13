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
- **Faithful layer, then opinionated layer.** `clean_infosiga()` fixes types and
  missing-value markers but never renames columns, recodes category labels or
  drops rows. Anything that rewrites what the source says — IBGE municipality
  spellings, Title Case, merged categories — belongs in `tidy_infosiga_labels()`,
  which users opt into. Do not move label recoding into `clean_infosiga()`.
- **Original column names are preserved** (Portuguese). Do not anglicise them;
  users cross-reference the official data dictionary (`infosiga_dictionary()`).
- **The cache is never poisoned by a bad download.** Downloads go to a tempfile,
  are validated (non-empty + ZIP magic bytes via `.infosiga_is_zip()`), and only
  then copied into the cache. A failed refresh leaves any existing archive intact.
- **Mirror fallback.** `infosigasp.zip_url`, `infosigasp.dictionary_url` and
  `infosigasp.manifest_url` may each be a vector of URLs tried in order: the
  official DETRAN-SP endpoint, then a GitHub-release mirror.
- **Staleness is local; updates are remote.** The staleness warning reads the ZIP
  member timestamps, so it reports how old the data are rather than how old the
  download is, and it never touches the network. Reusing a cache older than
  `infosigasp.stale_days` (default 30) warns. `infosiga_check_update()` is the
  only function that asks a remote what it holds, and it reads a small DCF
  manifest rather than the ~120 MB archive.

## Conventions

- Code style: RStudio section headers (`# Section ----`), per the global
  CLAUDE.md. Internal helpers and constants are prefixed `.infosiga_`.
- User-facing messages, warnings, and errors go through **cli** (`cli_abort`,
  `cli_warn`, `cli_alert_*`) — never base `stop`/`warning`/`message`.
- Source/URL/spec constants live in `R/infosiga-specs.R`. Behaviour is tunable
  through `options()`: `infosigasp.cache_dir`, `infosigasp.zip_url`,
  `infosigasp.dictionary_url`, `infosigasp.manifest_url`,
  `infosigasp.stale_days`.

## Testing

- Tests must run **offline**. Network paths are exercised by pointing the URL
  options at `file://` URLs (see `test-download.R`, `test-dictionary.R`,
  `test-update.R`).
- The cache is redirected to a tempdir via the `infosigasp.cache_dir` option;
  use the `local_infosiga_fixture()` helper (`helper-cache.R`) to seed it with
  the fixture archive `tests/testthat/fixtures/dados_infosiga.zip`. That helper
  disables the staleness check, because the fixture's ZIP members carry the date
  it was built and only get older. Tests that assert on staleness use
  `local_infosiga_aged_archive()`, which repacks the fixture with restamped
  members and skips when no `zip` binary is available.
- Fixtures: `dados_infosiga.zip` (minimal data archive, two period files per
  dataset) and `dicionario.zip` (dummy dictionary PDFs). Regenerate sample
  bundles and fixtures with `data-raw/sample-data.R`.
- testthat 3e. Prefer `withr::local_*` for option/tempdir cleanup.

## Useful commands

- `devtools::load_all()` / `devtools::test()` / `devtools::check()`
- `devtools::document()` after editing roxygen (regenerates `man/` + NAMESPACE)
- Rebuild the README from `README.Rmd` with `devtools::build_readme()`
