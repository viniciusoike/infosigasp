#' Open the INFOSIGA-SP data dictionary
#'
#' Opens the package's searchable online data dictionary. Set
#' `source = "official"` to open the INFOSIGA-SP source website instead.
#'
#' @param dataset Optional dataset to link to: one of `"sinistros"`,
#'   `"pessoas"` or `"veiculos"`. The online dictionary opens at that dataset's
#'   section. This argument has no effect when `source = "official"`.
#' @param source Which documentation to open. `"online"` (default) uses the
#'   searchable dictionary on the package website. `"official"` uses the
#'   INFOSIGA-SP website, where DETRAN-SP publishes the original files.
#' @param open Logical. If `TRUE` (the default in interactive sessions), open
#'   the URL in a browser.
#'
#' @return The selected URL, invisibly.
#'
#' @examples
#' dictionary_infosiga(open = FALSE)
#' dictionary_infosiga("sinistros", open = FALSE)
#' dictionary_infosiga(source = "official", open = FALSE)
#' @export
dictionary_infosiga <- function(
  dataset = NULL,
  source = c("online", "official"),
  open = interactive()
) {
  source <- match.arg(source)

  if (!is.null(dataset)) {
    dataset <- match.arg(dataset, .infosiga_datasets)
  }
  if (!is.logical(open) || length(open) != 1L || is.na(open)) {
    cli::cli_abort("{.arg open} must be `TRUE` or `FALSE`.")
  }

  url <- if (source == "online") {
    paste0(
      "https://viniciusoike.github.io/infosigasp/articles/data-dictionary.html",
      if (!is.null(dataset)) paste0("#", dataset) else ""
    )
  } else {
    "https://infosiga.detran.sp.gov.br/"
  }

  if (open) {
    utils::browseURL(url)
  }

  invisible(url)
}
