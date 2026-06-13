# infosigasp 0.1.0

* Initial release.
* `read_infosiga()` downloads (with caching) and imports the three INFOSIGA-SP
  datasets (`sinistros`, `pessoas`, `veiculos`) as tidy tibbles, handling the
  source encoding, decimal marks and date formats.
* `infosiga_download()` pre-fetches the source archive into a local cache.
* `infosiga_cache_dir()`, `infosiga_cache_list()` and `infosiga_cache_clear()`
  manage the on-disk cache.
* `infosiga_datasets()` lists the available datasets and their keys.
* `infosiga_dictionary()` downloads the official data dictionary.
