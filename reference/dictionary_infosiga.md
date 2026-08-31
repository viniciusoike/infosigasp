# Open the INFOSIGA-SP data dictionary

Opens the package's searchable online data dictionary. Set
`source = "official"` to open the INFOSIGA-SP source website instead.

## Usage

``` r
dictionary_infosiga(
  dataset = NULL,
  source = c("online", "official"),
  open = interactive()
)
```

## Arguments

- dataset:

  Optional dataset to link to: one of `"sinistros"`, `"pessoas"` or
  `"veiculos"`. The online dictionary opens at that dataset's section.
  This argument has no effect when `source = "official"`.

- source:

  Which documentation to open. `"online"` (default) uses the searchable
  dictionary on the package website. `"official"` uses the INFOSIGA-SP
  website, where DETRAN-SP publishes the original files.

- open:

  Logical. If `TRUE` (the default in interactive sessions), open the URL
  in a browser.

## Value

The selected URL, invisibly.

## Examples

``` r
dictionary_infosiga(open = FALSE)
dictionary_infosiga("sinistros", open = FALSE)
dictionary_infosiga(source = "official", open = FALSE)
```
