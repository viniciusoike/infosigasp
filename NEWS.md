# infosigasp 0.1.0

Initial release.

* Added `dictionary_infosiga()`, which downloads and returns the official PDF dictionaries for all datasets or a selected dataset.
* Added `read_infosiga()`, which downloads and imports the `sinistros`, `pessoas` and `veiculos` datasets as tibbles. Its `processing` argument provides lossless tabular `"raw"`, parsed `"typed"` and default `"clean"` modes; `standardize` selectively harmonises category labels, and `refresh = TRUE` updates the cached data. The first interactive download asks for confirmation and reports its approximate size. Unexpected categorical or integer representations are preserved with a warning rather than silently coerced.
* Removed the non-pushdown `year` argument from `read_infosiga()`; filter `ano_sinistro` after import when a year subset is needed.
* Documented the coverage caveats of the source data in `?read_infosiga` and the
  getting-started vignette, chief among them that 2015–2018 covers fatal crashes
  only, so an unrestricted per-year count jumps roughly 20-fold in 2019.
* Added a package hex logo drawn from the major road network of the São Paulo
  Metropolitan Region in the INFOSIGA-SP dark blue (`data-raw/logo.R`).
