# Cache helpers -------------------------------------------------------------

.infosiga_cache_dir <- function() {
  getOption(
    "infosigasp.cache_dir",
    tools::R_user_dir("infosigasp", which = "cache")
  )
}

.infosiga_ensure_cache_dir <- function() {
  dir <- .infosiga_cache_dir()
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  dir
}

.infosiga_archive_path <- function() {
  file.path(.infosiga_cache_dir(), .infosiga_zip_name)
}

.infosiga_dictionary_dir <- function() {
  file.path(.infosiga_cache_dir(), "dictionary")
}

.infosiga_processed_dir <- function() {
  file.path(.infosiga_cache_dir(), "processed")
}

.infosiga_cleaning_version <- 1L

.infosiga_source_id <- function(path = .infosiga_archive_path()) {
  if (!file.exists(path)) {
    return(NA_character_)
  }

  unname(tools::md5sum(path))
}

.infosiga_processed_path <- function(dataset, source_id) {
  dataset <- match.arg(dataset, .infosiga_datasets)

  file.path(
    .infosiga_processed_dir(),
    paste0(
      dataset,
      "-clean-v",
      .infosiga_cleaning_version,
      "-",
      source_id,
      ".rds"
    )
  )
}

.infosiga_valid_processed_record <- function(record, dataset, source_id) {
  is.list(record) &&
    identical(record$format_version, 1L) &&
    identical(record$cleaning_version, .infosiga_cleaning_version) &&
    identical(record$dataset, dataset) &&
    identical(record$source_id, source_id) &&
    inherits(record$data, "tbl_df")
}

.infosiga_read_processed <- function(path, dataset, source_id, quiet = FALSE) {
  if (!file.exists(path)) {
    return(NULL)
  }

  record <- tryCatch(readRDS(path), error = function(error) NULL)
  if (.infosiga_valid_processed_record(record, dataset, source_id)) {
    return(record$data)
  }

  unlink(path)
  if (!quiet) {
    cli::cli_alert_warning(
      "Removed an invalid processed-cache file; rebuilding it from the source archive."
    )
  }
  NULL
}

.infosiga_prune_processed <- function(dataset, keep) {
  directory <- .infosiga_processed_dir()
  if (!dir.exists(directory)) {
    return(invisible(character()))
  }

  pattern <- paste0("^", dataset, "-clean-v[0-9]+-[a-f0-9]+\\.rds$")
  candidates <- list.files(directory, pattern = pattern, full.names = TRUE)
  obsolete <- setdiff(candidates, keep)
  if (length(obsolete)) {
    unlink(obsolete)
  }

  invisible(obsolete)
}

.infosiga_prune_stale_processed <- function(source_id) {
  directory <- .infosiga_processed_dir()
  if (!dir.exists(directory)) {
    return(invisible(character()))
  }

  dataset_pattern <- paste(.infosiga_datasets, collapse = "|")
  pattern <- paste0(
    "^(",
    dataset_pattern,
    ")-clean-v[0-9]+-[a-f0-9]+\\.rds$"
  )
  candidates <- list.files(directory, pattern = pattern, full.names = TRUE)
  current_suffix <- paste0(
    "-clean-v",
    .infosiga_cleaning_version,
    "-",
    source_id,
    ".rds"
  )
  stale <- candidates[!endsWith(candidates, current_suffix)]
  if (length(stale)) {
    unlink(stale)
  }

  invisible(stale)
}

.infosiga_write_processed <- function(
  data,
  path,
  dataset,
  source_id,
  quiet = FALSE
) {
  directory <- dirname(path)
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)

  temporary <- tempfile(
    pattern = paste0(".", dataset, "-"),
    tmpdir = directory,
    fileext = ".rds"
  )
  on.exit(unlink(temporary), add = TRUE)

  record <- list(
    format_version = 1L,
    cleaning_version = .infosiga_cleaning_version,
    dataset = dataset,
    source_id = source_id,
    data = data
  )

  saved <- tryCatch(
    {
      saveRDS(record, temporary, compress = "gzip", version = 3L)
      TRUE
    },
    error = function(error) {
      if (!quiet) {
        cli::cli_alert_warning(
          "Could not save the processed cache: {conditionMessage(error)}"
        )
      }
      FALSE
    }
  )
  if (!saved) {
    return(invisible(FALSE))
  }

  installed <- file.rename(temporary, path)
  if (!installed && file.exists(path)) {
    cached <- .infosiga_read_processed(path, dataset, source_id, quiet = TRUE)
    installed <- !is.null(cached)
  }
  if (!installed) {
    if (!quiet) {
      cli::cli_alert_warning("Could not install the processed-cache file.")
    }
    return(invisible(FALSE))
  }

  .infosiga_prune_processed(dataset, keep = path)
  invisible(TRUE)
}

#' Inspect the INFOSIGA-SP cache
#'
#' Lists the source archive and canonical cleaned datasets currently stored in
#' the package cache. Merely inspecting the cache does not create any files or
#' directories.
#'
#' @return A tibble with the cache entry type, dataset, absolute path, size in
#'   MiB and modification time. Returns an empty tibble when the cache is empty.
#'
#' @seealso [read_infosiga()] and [clear_infosiga_cache()].
#' @examples
#' infosiga_cache_info()
#' @export
infosiga_cache_info <- function() {
  source <- .infosiga_archive_path()
  processed_dir <- .infosiga_processed_dir()
  processed <- if (dir.exists(processed_dir)) {
    list.files(processed_dir, pattern = "\\.rds$", full.names = TRUE)
  } else {
    character()
  }
  paths <- c(if (file.exists(source)) source, processed)

  if (!length(paths)) {
    return(tibble::tibble(
      type = character(),
      dataset = character(),
      path = character(),
      size_mb = double(),
      modified = as.POSIXct(character())
    ))
  }

  info <- file.info(paths)
  is_source <- paths == source
  names <- basename(paths)
  dataset <- ifelse(
    is_source,
    NA_character_,
    sub("-clean-v[0-9]+-[a-f0-9]+\\.rds$", "", names)
  )

  tibble::tibble(
    type = ifelse(is_source, "source", "processed"),
    dataset = dataset,
    path = normalizePath(paths, winslash = "/", mustWork = FALSE),
    size_mb = unname(info$size) / 1024^2,
    modified = info$mtime
  )
}

#' Clear the INFOSIGA-SP cache
#'
#' Removes package-managed cache entries. By default, only canonical cleaned
#' datasets are removed; the downloaded source archive is retained. Files
#' outside the package's managed cache paths are never touched.
#'
#' @param processed Logical. Remove all canonical cleaned datasets.
#' @param source Logical. Also remove the downloaded source ZIP archive.
#' @param quiet Logical. Suppress the completion message.
#'
#' @return Invisibly, the paths that were selected for removal.
#'
#' @seealso [infosiga_cache_info()] and [read_infosiga()].
#' @examples
#' temporary_cache <- tempfile("infosigasp-example-")
#' old_options <- options(infosigasp.cache_dir = temporary_cache)
#' clear_infosiga_cache(quiet = TRUE)
#' options(old_options)
#' @export
clear_infosiga_cache <- function(
  processed = TRUE,
  source = FALSE,
  quiet = FALSE
) {
  arguments <- list(processed = processed, source = source, quiet = quiet)
  valid <- vapply(
    arguments,
    \(x) is.logical(x) && length(x) == 1L && !is.na(x),
    logical(1)
  )
  if (!all(valid)) {
    cli::cli_abort(
      "{.arg processed}, {.arg source} and {.arg quiet} must be `TRUE` or `FALSE`."
    )
  }

  paths <- character()
  if (processed && dir.exists(.infosiga_processed_dir())) {
    paths <- c(paths, .infosiga_processed_dir())
    unlink(.infosiga_processed_dir(), recursive = TRUE)
  }
  if (source && file.exists(.infosiga_archive_path())) {
    paths <- c(paths, .infosiga_archive_path())
    unlink(.infosiga_archive_path())
  }

  if (!quiet) {
    cli::cli_alert_success(
      "Cleared {length(paths)} infosigasp cache entr{?y/ies}."
    )
  }
  invisible(paths)
}
