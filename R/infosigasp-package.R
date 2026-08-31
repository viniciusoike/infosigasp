#' infosigasp: Download and Import Traffic Crash Data from INFOSIGA-SP
#'
#' The infosigasp package provides a programmatic interface to the open data
#' published by the Sao Paulo State Traffic Accident Information and Management
#' System (INFOSIGA-SP), maintained by the Sao Paulo State Department of Motor
#' Vehicles (DETRAN-SP).
#'
#' INFOSIGA-SP distributes three related datasets of occurrence records from
#' 2015 onward. Coverage and definitions vary over time; notably, 2015--2018
#' covers fatal crashes only, and the events table includes notifications that
#' have not yet been confirmed as crashes.
#'
#' \describe{
#'   \item{`sinistros`}{Occurrence records: one row per confirmed crash or
#'     notification, with date, time, location and a breakdown of vehicles and
#'     victims by severity.}
#'   \item{`pessoas`}{Victims: one row per person involved, with demographic
#'     attributes, injury severity and, for fatalities, the date of death.}
#'   \item{`veiculos`}{Vehicles: one row per vehicle involved, with make,
#'     model, year and type.}
#' }
#'
#' The three datasets can be linked through the `id_sinistro` key (and
#' `id_veiculo`, where applicable).
#'
#' @section Main functions:
#' \describe{
#'   \item{[read_infosiga()]}{Download (if needed) and import a dataset as a
#'     tibble.}
#'   \item{[dictionary_infosiga()]}{Open the searchable data dictionary or the
#'     official source website.}
#' }
#'
#' @section Data source and licence:
#' DETRAN-SP publishes the data under a Creative Commons Attribution 4.0
#' licence at <https://infosiga.detran.sp.gov.br/>. This package is not
#' affiliated with or endorsed by DETRAN-SP or the Government of the State of
#' Sao Paulo.
#'
#' @keywords internal
"_PACKAGE"
