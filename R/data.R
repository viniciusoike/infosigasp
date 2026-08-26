#' Municipalities of Sao Paulo state, as named by IBGE and by INFOSIGA-SP
#'
#' A lookup pairing each of the 645 municipalities of the state of Sao Paulo
#' with both spellings that appear in practice: the official IBGE name and the
#' unaccented upper-case form INFOSIGA-SP publishes. It powers the place-name
#' tidying in [tidy_infosiga_labels()]. The `cod_ibge` key also joins
#' INFOSIGA-SP to census, population and boundary data, the denominators that
#' turn crash counts into crash rates.
#'
#' @format A [tibble][tibble::tibble] with 645 rows and 5 columns:
#' \describe{
#'   \item{cod_ibge}{IBGE municipality code, 7 digits, as character to preserve
#'     the form used across the INFOSIGA-SP datasets. The join key.}
#'   \item{municipio}{Official IBGE name, accented and mixed case (shown here
#'     unaccented as `"Sao Jose dos Campos"`; the data carry the accents).}
#'   \item{municipio_infosiga}{The spelling INFOSIGA-SP publishes: upper case
#'     with accents stripped (`"SAO JOSE DOS CAMPOS"`).}
#'   \item{regiao_administrativa}{One of the 16 administrative regions of Sao
#'     Paulo state, Title Cased.}
#'   \item{regiao_administrativa_infosiga}{The spelling INFOSIGA-SP publishes:
#'     upper case, but with its accents intact, unlike `municipio`.}
#' }
#'
#' @details
#' Always join on `cod_ibge`, never on the name. Nine municipalities are spelt
#' differently by the two sources: eight contain an apostrophe that INFOSIGA-SP
#' renders as a space (`"Santa Barbara d'Oeste"` against
#' `"SANTA BARBARA D OESTE"`), and IBGE's `"Sao Luiz do Paraitinga"` appears in
#' INFOSIGA-SP as `"SAO LUIS DO PARAITINGA"`. A name join silently loses those
#' nine.
#'
#' @source Municipality names and codes from the IBGE localities API,
#'   <https://servicodados.ibge.gov.br/api/v1/localidades/estados/35/municipios>.
#'   The INFOSIGA-SP spellings and the municipality-to-region assignment are
#'   taken from the `sinistros` dataset itself. Rebuilt by
#'   `data-raw/municipios.R`.
#'
#' @seealso [tidy_infosiga_labels()], which uses this lookup.
#'
#' @examples
#' head(infosiga_municipios)
#'
#' # The nine municipalities whose names differ by more than accents and case.
#' # chartr() rather than iconv(to = "ASCII//TRANSLIT"), which is locale- and
#' # platform-dependent; the accented letters are built with intToUtf8().
#' accented <- intToUtf8(c(
#'   0x00c1, 0x00c0, 0x00c2, 0x00c3, 0x00c9, 0x00ca,
#'   0x00cd, 0x00d3, 0x00d4, 0x00d5, 0x00da, 0x00c7,
#'   0x00e1, 0x00e0, 0x00e2, 0x00e3, 0x00e9, 0x00ea,
#'   0x00ed, 0x00f3, 0x00f4, 0x00f5, 0x00fa, 0x00e7
#' ))
#' folded <- toupper(chartr(
#'   accented,
#'   "AAAAEEIOOOUCaaaaeeiooouc",
#'   infosiga_municipios$municipio
#' ))
#' subset(
#'   infosiga_municipios,
#'   folded != municipio_infosiga,
#'   select = c(cod_ibge, municipio, municipio_infosiga)
#' )
"infosiga_municipios"
