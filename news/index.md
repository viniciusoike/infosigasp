# Changelog

## infosigasp 0.1.0

- Initial release.
- [`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
  downloads (with caching) and imports the three INFOSIGA-SP datasets
  (`sinistros`, `pessoas`, `veiculos`) as tidy tibbles, handling the
  source encoding, decimal marks and date formats.
- [`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md)
  returns a processed dataset by default (`clean = TRUE`): ordinal
  columns (`dia_da_semana`, `turno`, `gravidade_lesao`, age bands)
  become ordered factors, `"NAO DISPONIVEL"` becomes `NA`, and
  impossible coordinates are dropped. Use `clean = FALSE` for the raw
  data as published, or
  [`clean_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/clean_infosiga.md)
  to process a raw import afterwards.
- [`infosiga_download()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_download.md)
  pre-fetches the source archive into a local cache.
- [`infosiga_cache_dir()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md),
  [`infosiga_cache_list()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md)
  and
  [`infosiga_cache_clear()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md)
  manage the on-disk cache.
- [`infosiga_datasets()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_datasets.md)
  lists the available datasets and their keys.
- [`infosiga_dictionary()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_dictionary.md)
  downloads the official data dictionary.
