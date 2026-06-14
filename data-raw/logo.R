# Generate the package hex logo: the major road network of the Sao Paulo
# Metropolitan Region, drawn in the INFOSIGA-SP dark blue.
#
# The map combines the metropolitan boundary from {geobr} with the
# motorway / trunk / primary road network from OpenStreetMap via {osmdata}.
# Run this script to regenerate man/figures/logo.png.

library(geobr)
library(osmdata)
library(sf)
library(ggplot2)
library(hexSticker)
library(sysfonts)
library(showtext)

## Colors ----------------------------------------------------------------

# Dark blue used across the INFOSIGA-SP portal dashboard panels.
navy <- "#1044A8"
# A slightly lighter blue for the secondary (primary-class) roads.
blue_light <- "#3D6BC4"

## Sao Paulo Metropolitan Region boundary --------------------------------

metro <- read_metro_area(year = 2018, showProgress = FALSE)
rmsp <- metro[
  grepl("^Rm", metro$name_metro) & grepl("Paulo", metro$name_metro),
]
rmsp <- st_transform(st_make_valid(st_union(st_make_valid(rmsp))), 4326)

## Major roads from OpenStreetMap ----------------------------------------

roads_q <- opq(bbox = as.numeric(st_bbox(rmsp)), timeout = 120)
roads_q <- add_osm_feature(
  roads_q,
  key = "highway",
  value = c("motorway", "trunk", "primary")
)
roads_raw <- osmdata_sf(roads_q)$osm_lines[, c("osm_id", "highway")]
roads <- suppressWarnings(st_intersection(st_make_valid(roads_raw), rmsp))

# Draw thicker, darker classes last so they sit on top.
roads$lwd <- c(motorway = 0.25, trunk = 0.15, primary = 0.05)[roads$highway]
roads <- roads[order(match(roads$highway, c("primary", "trunk", "motorway"))), ]

## Road-network sub-plot -------------------------------------------------

colors_roads <- c(
  motorway = "#FFAA5A",
  trunk = "#FFBE5A",
  primary = "#FFD25A"
)


# Crop to a square window centred on the city so the radial network and the
# Rodoanel beltway fill the hexagon.
road_map <- ggplot(roads) +
  geom_sf(aes(linewidth = lwd, color = highway), lineend = "round") +
  scale_linewidth_identity() +
  scale_color_manual(values = colors_roads) +
  coord_sf(xlim = c(-47.02, -46.18), ylim = c(-23.92, -23.20), expand = FALSE) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "#1044A8", color = NA),
    panel.background = element_rect(fill = "#1044A8", color = NA),
    legend.position = "none"
  )

## Hex sticker -----------------------------------------------------------

font_add_google("Barlow Semi Condensed", "barlow")
# showtext_opts(dpi = 300)
showtext_auto()

# Drop the map low enough to leave a clean white band for the wordmark.
sticker(
  subplot = road_map,
  s_x = 1,
  s_y = 0.8,
  s_width = 2.3,
  s_height = 1.5,
  package = "infosigasp",
  p_family = "barlow",
  p_fontface = "bold",
  p_color = "#ffffff",
  p_size = 24,
  p_x = 1,
  p_y = 1.55,
  h_fill = "#1044A8",
  h_color = "#000000",
  u_color = navy,
  u_size = 4.0,
  u_y = 0.08,
  filename = "man/figures/logo.png",
  white_around_sticker = TRUE,
  dpi = 400
)
