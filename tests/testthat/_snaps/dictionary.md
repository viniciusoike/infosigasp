# dictionary_infosiga validates its arguments

    Code
      dictionary_infosiga("other", open = FALSE)
    Condition
      Error in `match.arg()`:
      ! 'arg' should be one of "sinistros", "pessoas", "veiculos"

---

    Code
      dictionary_infosiga(source = "other", open = FALSE)
    Condition
      Error in `match.arg()`:
      ! 'arg' should be one of "online", "official"

---

    Code
      dictionary_infosiga(open = NA)
    Condition
      Error in `dictionary_infosiga()`:
      ! `open` must be `TRUE` or `FALSE`.

