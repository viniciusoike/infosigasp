# unexpected ordinal values are preserved with a warning

    Code
      out <- .infosiga_clean(raw, "sinistros")
    Condition
      Warning:
      There was 1 warning in `dplyr::mutate()`.
      i In argument: `dplyr::across(...)`.
      Caused by warning:
      ! Column turno contains unexpected source values and was left unchanged.
      i Expected: "MADRUGADA", "MANHA", "TARDE", and "NOITE".
      i Found: "NOVO TURNO".

# unexpected flag values are preserved with a warning

    Code
      out <- .infosiga_clean(raw, "sinistros")
    Condition
      Warning:
      There was 1 warning in `dplyr::mutate()`.
      i In argument: `dplyr::across(...)`.
      Caused by warning:
      ! Column tp_sinistro_choque contains unexpected source values and was left unchanged.
      i Expected: "S".
      i Found: "VALOR NOVO".

# invalid integer strings are preserved with a warning

    Code
      out <- .infosiga_clean(raw, "pessoas")
    Condition
      Warning:
      There was 1 warning in `dplyr::mutate()`.
      i In argument: `tempo_sinistro_obito = .infosiga_as_integer(data$tempo_sinistro_obito, "tempo_sinistro_obito")`.
      Caused by warning:
      ! Column tempo_sinistro_obito contains unexpected source values and was left unchanged.
      i Expected integer strings.
      i Found: "1.5", "ERRO", and "999999999999".
