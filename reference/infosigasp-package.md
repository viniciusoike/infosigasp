# infosigasp: Download and Import Traffic Crash Data from INFOSIGA-SP

The infosigasp package provides a programmatic interface to the open
data published by the Sao Paulo State Traffic Accident Information and
Management System (INFOSIGA-SP), maintained by the Sao Paulo State
Department of Motor Vehicles (DETRAN-SP).

## Details

INFOSIGA-SP distributes three related datasets covering every traffic
crash recorded in the state of Sao Paulo, Brazil, from 2015 onward.

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

- [`dictionary_infosiga()`](https://viniciusoike.github.io/infosigasp/reference/dictionary_infosiga.md):

  Download and locate the official data dictionaries.

## Data source and licence

DETRAN-SP publishes the data under a Creative Commons Attribution 4.0
licence at <https://infosiga.detran.sp.gov.br/>. This package is not
affiliated with or endorsed by DETRAN-SP or the Government of the State
of Sao Paulo.

## See also

Useful links:

- <https://github.com/viniciusoike/infosigasp>

- <https://viniciusoike.github.io/infosigasp/>

- Report bugs at <https://github.com/viniciusoike/infosigasp/issues>

## Author

**Maintainer**: Vinicius Oike <viniciusoike@gmail.com>
([ORCID](https://orcid.org/0009-0005-8015-9189)) \[copyright holder\]
