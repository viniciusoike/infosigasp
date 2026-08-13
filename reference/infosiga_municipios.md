# Municipalities of Sao Paulo state, as named by IBGE and by INFOSIGA-SP

A lookup pairing each of the 645 municipalities of the state of Sao
Paulo with both spellings that appear in practice: the official IBGE
name and the unaccented upper-case form INFOSIGA-SP publishes. It powers
the place-name tidying in
[`tidy_infosiga_labels()`](https://viniciusoike.github.io/infosigasp/reference/tidy_infosiga_labels.md).
The `cod_ibge` key also joins INFOSIGA-SP to census, population and
boundary data, the denominators that turn crash counts into crash rates.

## Usage

``` r
infosiga_municipios
```

## Format

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with 645
rows and 5 columns:

- cod_ibge:

  IBGE municipality code, 7 digits, as character to preserve the form
  used across the INFOSIGA-SP datasets. The join key.

- municipio:

  Official IBGE name, accented and mixed case (shown here unaccented as
  `"Sao Jose dos Campos"`; the data carry the accents).

- municipio_infosiga:

  The spelling INFOSIGA-SP publishes: upper case with accents stripped
  (`"SAO JOSE DOS CAMPOS"`).

- regiao_administrativa:

  One of the 16 administrative regions of Sao Paulo state, Title Cased.

- regiao_administrativa_infosiga:

  The spelling INFOSIGA-SP publishes: upper case, but with its accents
  intact, unlike `municipio`.

## Source

Municipality names and codes from the IBGE localities API,
<https://servicodados.ibge.gov.br/api/v1/localidades/estados/35/municipios>.
The INFOSIGA-SP spellings and the municipality-to-region assignment are
taken from the `sinistros` dataset itself. Rebuilt by
`data-raw/municipios.R`.

## Details

Always join on `cod_ibge`, never on the name. Nine municipalities are
spelt differently by the two sources: eight contain an apostrophe that
INFOSIGA-SP renders as a space (`"Santa Barbara d'Oeste"` against
`"SANTA BARBARA D OESTE"`), and IBGE's `"Sao Luiz do Paraitinga"`
appears in INFOSIGA-SP as `"SAO LUIS DO PARAITINGA"`. A name join
silently loses those nine.

## See also

[`tidy_infosiga_labels()`](https://viniciusoike.github.io/infosigasp/reference/tidy_infosiga_labels.md),
which uses this lookup.

## Examples

``` r
head(infosiga_municipios)
#> # A tibble: 6 × 5
#>   cod_ibge municipio              municipio_infosiga     regiao_administrativa
#>   <chr>    <chr>                  <chr>                  <chr>                
#> 1 3500105  Adamantina             ADAMANTINA             Presidente Prudente  
#> 2 3500204  Adolfo                 ADOLFO                 São José do Rio Preto
#> 3 3500303  Aguaí                  AGUAI                  Campinas             
#> 4 3500402  Águas da Prata         AGUAS DA PRATA         Campinas             
#> 5 3500501  Águas de Lindóia       AGUAS DE LINDOIA       Campinas             
#> 6 3500550  Águas de Santa Bárbara AGUAS DE SANTA BARBARA Sorocaba             
#> # ℹ 1 more variable: regiao_administrativa_infosiga <chr>

# The nine municipalities whose names differ between the two sources
folded <- gsub("'", " ", toupper(infosiga_municipios$municipio))
subset(
  infosiga_municipios,
  iconv(folded, "UTF-8", "ASCII", sub = "?") != municipio_infosiga,
  select = c(cod_ibge, municipio, municipio_infosiga)
)
#> # A tibble: 274 × 3
#>    cod_ibge municipio              municipio_infosiga    
#>    <chr>    <chr>                  <chr>                 
#>  1 3500303  Aguaí                  AGUAI                 
#>  2 3500402  Águas da Prata         AGUAS DA PRATA        
#>  3 3500501  Águas de Lindóia       AGUAS DE LINDOIA      
#>  4 3500550  Águas de Santa Bárbara AGUAS DE SANTA BARBARA
#>  5 3500600  Águas de São Pedro     AGUAS DE SAO PEDRO    
#>  6 3501004  Altinópolis            ALTINOPOLIS           
#>  7 3501152  Alumínio               ALUMINIO              
#>  8 3501202  Álvares Florence       ALVARES FLORENCE      
#>  9 3501301  Álvares Machado        ALVARES MACHADO       
#> 10 3501400  Álvaro de Carvalho     ALVARO DE CARVALHO    
#> # ℹ 264 more rows
```
