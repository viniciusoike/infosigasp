# Build the buffered Sao Paulo state boundary used to validate coordinates.

library(geobr)
library(sf)

# Preserve the municipality lookup stored in the same internal data file.
internal_data <- new.env(parent = emptyenv())
load("R/sysdata.rda", envir = internal_data)
infosiga_municipios <- internal_data$infosiga_municipios

spo_shape <- read_state(year = 2022, simplified = FALSE) |>
  subset(code_state == 35) |>
  st_transform(crs = 31983) |>
  st_buffer(dist = 2000) |>
  st_transform(crs = 4326) |>
  st_make_valid() |>
  st_geometry()

stopifnot(
  length(spo_shape) == 1,
  st_crs(spo_shape)$epsg == 4326,
  all(st_is_valid(spo_shape))
)

usethis::use_data(
  infosiga_municipios,
  spo_shape,
  internal = TRUE,
  overwrite = TRUE
)
