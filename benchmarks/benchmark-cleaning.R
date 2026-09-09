# Benchmark the full sinistros cleaning pipeline ----------------------------

# Run from the package root with:
# Rscript benchmarks/benchmark-cleaning.R [repetitions]
#
# The script reads the archive from the normal infosigasp cache. It does not
# download with refresh = TRUE and does not write benchmark results to disk.

args <- commandArgs(trailingOnly = TRUE)
repetitions <- if (length(args)) as.integer(args[[1]]) else 3L

if (is.na(repetitions) || repetitions < 1L) {
  stop("repetitions must be a positive integer", call. = FALSE)
}

devtools::load_all(quiet = TRUE)

elapsed <- function(code, repetitions) {
  times <- numeric(repetitions)

  for (i in seq_len(repetitions)) {
    gc()
    times[[i]] <- system.time(force(code()))[["elapsed"]]
  }

  c(
    median = stats::median(times),
    minimum = min(times),
    maximum = max(times)
  )
}

benchmark <- function(name, code, repetitions) {
  timing <- elapsed(code, repetitions)

  data.frame(
    benchmark = name,
    median_seconds = unname(timing[["median"]]),
    minimum_seconds = unname(timing[["minimum"]]),
    maximum_seconds = unname(timing[["maximum"]])
  )
}

valid_coordinates_unique <- function(latitude, longitude) {
  valid <- rep(FALSE, length(latitude))
  boundary <- sf::st_bbox(spo_shape)

  candidates <- is.finite(latitude) &
    is.finite(longitude) &
    dplyr::between(latitude, boundary[["ymin"]], boundary[["ymax"]]) &
    dplyr::between(longitude, boundary[["xmin"]], boundary[["xmax"]])

  if (!any(candidates)) {
    return(valid)
  }

  candidate_rows <- which(candidates)
  pairs <- data.frame(
    longitude = longitude[candidates],
    latitude = latitude[candidates]
  )
  unique_rows <- !duplicated(pairs)
  unique_pairs <- pairs[unique_rows, , drop = FALSE]
  keys <- paste(pairs$longitude, pairs$latitude, sep = "\r")
  unique_keys <- keys[unique_rows]

  points <- sf::st_as_sf(
    unique_pairs,
    coords = c("longitude", "latitude"),
    crs = 4326
  )
  unique_valid <- lengths(sf::st_intersects(points, spo_shape)) > 0

  valid[candidate_rows] <- unique_valid[match(keys, unique_keys)]
  valid
}

cli::cli_alert_info("Reading typed {.val sinistros} from the local cache.")
import_time <- system.time(
  sinistros <- read_infosiga(
    "sinistros",
    processing = "typed",
    quiet = TRUE
  )
)

without_coordinates <- sinistros |>
  dplyr::select(-dplyr::all_of(c("latitude", "longitude")))

trim_characters <- function(data) {
  data |>
    dplyr::mutate(
      dplyr::across(
        dplyr::where(is.character),
        function(x) {
          x |>
            stringr::str_trim() |>
            dplyr::replace_values("NAO DISPONIVEL" ~ NA_character_)
        }
      )
    )
}

current_valid <- .infosiga_valid_coordinates(
  sinistros$latitude,
  sinistros$longitude
)
unique_valid <- valid_coordinates_unique(
  sinistros$latitude,
  sinistros$longitude
)

if (!identical(current_valid, unique_valid)) {
  stop(
    "The unique-coordinate prototype changed validation results.",
    call. = FALSE
  )
}

boundary <- sf::st_bbox(spo_shape)
candidates <- is.finite(sinistros$latitude) &
  is.finite(sinistros$longitude) &
  dplyr::between(
    sinistros$latitude,
    boundary[["ymin"]],
    boundary[["ymax"]]
  ) &
  dplyr::between(
    sinistros$longitude,
    boundary[["xmin"]],
    boundary[["xmax"]]
  )
coordinate_pairs <- data.frame(
  latitude = sinistros$latitude[candidates],
  longitude = sinistros$longitude[candidates]
)

results <- dplyr::bind_rows(
  benchmark(
    "full cleaning",
    \() .infosiga_clean(sinistros, "sinistros"),
    repetitions
  ),
  benchmark(
    "cleaning without coordinate columns",
    \() .infosiga_clean(without_coordinates, "sinistros"),
    repetitions
  ),
  benchmark(
    "character trimming and missing markers",
    \() trim_characters(sinistros),
    repetitions
  ),
  benchmark(
    "current coordinate validation",
    \() {
      .infosiga_valid_coordinates(
        sinistros$latitude,
        sinistros$longitude
      )
    },
    repetitions
  ),
  benchmark(
    "unique-coordinate prototype",
    \() {
      valid_coordinates_unique(
        sinistros$latitude,
        sinistros$longitude
      )
    },
    repetitions
  )
)

summary <- data.frame(
  metric = c(
    "rows",
    "coordinate candidates",
    "unique candidate pairs",
    "typed object (MiB)",
    "typed import (seconds)"
  ),
  value = c(
    nrow(sinistros),
    sum(candidates),
    nrow(unique(coordinate_pairs)),
    as.numeric(object.size(sinistros)) / 1024^2,
    import_time[["elapsed"]]
  )
)

cli::cli_h1("Cleaning benchmarks")
print(results, row.names = FALSE, digits = 3)
cli::cli_h1("Dataset summary")
print(summary, row.names = FALSE, digits = 7)
