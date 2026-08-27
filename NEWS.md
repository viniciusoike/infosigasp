# infosigasp 0.1.0

Initial release.

* Added `dictionary_infosiga()`, which downloads and returns the official PDF dictionaries for all datasets or a selected dataset.
* Added `read_infosiga()`, which downloads and imports the `sinistros`, `pessoas` and `veiculos` datasets as tibbles. It handles source encoding, types and cleaning, supports raw data with `clean = FALSE`, standardises inconsistent category labels with `labels = TRUE`, and refreshes the local data with `refresh = TRUE`. The first interactive download asks for confirmation and reports its approximate size.
* Documented the coverage caveats of the source data in `?read_infosiga` and the
  getting-started vignette, chief among them that 2015–2018 covers fatal crashes
  only, so an unrestricted per-year count jumps roughly 20-fold in 2019.
* Added a package hex logo drawn from the major road network of the São Paulo
  Metropolitan Region in the INFOSIGA-SP dark blue (`data-raw/logo.R`).
