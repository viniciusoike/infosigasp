# invalid arguments are rejected

    Code
      read_infosiga("foo", quiet = TRUE)
    Condition
      Error in `match.arg()`:
      ! 'arg' should be one of "sinistros", "pessoas", "veiculos"

---

    Code
      read_infosiga("sinistros", processing = "other", quiet = TRUE)
    Condition
      Error in `match.arg()`:
      ! 'arg' should be one of "clean", "typed", "raw"

---

    Code
      read_infosiga("sinistros", refresh = NA, quiet = TRUE)
    Condition
      Error in `read_infosiga()`:
      ! `refresh` must be `TRUE` or `FALSE`.

---

    Code
      read_infosiga("sinistros", cache = NA, quiet = TRUE)
    Condition
      Error in `read_infosiga()`:
      ! `cache` must be `TRUE` or `FALSE`.

---

    Code
      read_infosiga("sinistros", processing = "typed", standardize = "municipios",
        quiet = TRUE)
    Condition
      Error in `read_infosiga()`:
      ! `standardize` requires the "clean" processing mode.

# the first interactive download asks for confirmation

    Code
      .infosiga_confirm_download(is_interactive = TRUE, ask = function(...) FALSE)
    Message
      INFOSIGA-SP data are not available locally.
      i The download is approximately 120 MB and will be stored in your user cache.
    Condition
      Error in `.infosiga_confirm_download()`:
      ! Download cancelled; no files were added to your cache.

