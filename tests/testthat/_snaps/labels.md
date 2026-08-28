# .infosiga_standardize preserves dimensions and validates choices

    Code
      .infosiga_standardize(raw, "carros")
    Condition
      Error in `match.arg()`:
      ! 'arg' should be one of "sinistros", "pessoas", "veiculos"

---

    Code
      .infosiga_standardize(raw, "veiculos", "municipios")
    Condition
      Error in `.infosiga_standardize()`:
      ! Some requested standardisations are not available for "veiculos": "municipios".
      i Available for this dataset: "cores".

---

    Code
      .infosiga_standardize(raw, "veiculos", "desconhecido")
    Condition
      Error in `.infosiga_standardize()`:
      ! Unknown `standardize` value: "desconhecido".
      i Choose from "municipios", "profissoes", and "cores" or "all".

---

    Code
      .infosiga_standardize(raw, "veiculos", c("all", "cores"))
    Condition
      Error in `.infosiga_standardize()`:
      ! "all" cannot be combined with individual `standardize` values.

