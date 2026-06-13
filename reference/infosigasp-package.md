# infosigasp: Download and Import Traffic Crash Data from INFOSIGA-SP

The infosigasp package provides a programmatic interface to the open
data published by the Sao Paulo State Traffic Accident Information and
Management System (INFOSIGA-SP), maintained by the Sao Paulo State
Department of Motor Vehicles (DETRAN-SP).

## Details

INFOSIGA-SP distributes three related datasets covering every traffic
crash recorded in the state of Sao Paulo, Brazil, from 2015 onward:

- `sinistros`:

  Crash events: one row per recorded event, with date, time, location
  and a breakdown of vehicles and victims by severity.

- `pessoas`:

  Victims: one row per person involved, with demographic attributes,
  injury severity and, for fatalities, the date of death.

- `veiculos`:

  Vehicles: one row per vehicle involved, with make, model, year and
  type.

The three datasets can be linked through the `id_sinistro` key (and
`id_veiculo`, where applicable).

## Main functions

- [`read_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/read_infosiga.md):

  Download (if needed) and import a dataset as a tibble.

- [`infosiga_download()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_download.md):

  Download the raw source archive to the local cache.

- [`infosiga_cache_dir()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md),
  [`infosiga_cache_list()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md),
  [`infosiga_cache_clear()`](https://viniciusoike.github.io/infosigasp/reference/infosiga_cache.md):

  Manage the on-disk cache.

## Data source and licence

Data are published by DETRAN-SP under a Creative Commons Attribution 4.0
licence at <https://infosiga.detran.sp.gov.br/>. This package is not
affiliated with or endorsed by DETRAN-SP or the Government of the State
of Sao Paulo.

## See also

Useful links:

- <https://github.com/viniciusoike/infosigasp>

- <https://viniciusoike.github.io/infosigasp/>

- Report bugs at <https://github.com/viniciusoike/infosigasp/issues>

## Author

**Maintainer**: Vinicius Oike <viniciusoike@gmail.com> \[copyright
holder\]
