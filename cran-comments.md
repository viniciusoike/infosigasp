## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release, so R CMD check reports one NOTE flagging it as a new
  submission (`Maintainer: ...` / "New submission").

## Test environments

* local macOS, R release
* GitHub Actions: Ubuntu (devel, release, oldrel-1), macOS (release),
  Windows (release)

## Notes for the reviewer

* The package downloads a large (~120 MB) open-data archive published by the
  São Paulo State Department of Motor Vehicles (DETRAN-SP). To respect CRAN
  policy, no example, test or vignette accesses the network: the network paths
  are exercised against bundled fixtures via local `file://` URLs, and all
  downloading examples are wrapped in `\dontrun{}`. Downloaded files are stored
  under `tools::R_user_dir("infosigasp", "cache")`, and the cache directory is
  created lazily only when data is actually written.

* There are no published references describing the methods in this package; it
  implements original functionality for accessing and tidying the INFOSIGA-SP
  open dataset.

* 'INFOSIGA-SP' and 'DETRAN-SP' are proper names (a public traffic-accident
  data system and its maintaining agency) and are intentionally quoted in the
  Title and Description.

* The words "Sao", "Paulo", "sinistros", "pessoas" and "veiculos" flagged as
  possibly misspelled in the DESCRIPTION are, respectively, the
  (ASCII-transliterated) name of the Brazilian state of Sao Paulo and the
  Portuguese names of the three published datasets.
