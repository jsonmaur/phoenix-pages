locals_without_parens = [pages: 3, pages: 4]

[
  inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}"],
  export: [locals_without_parens: locals_without_parens],
  locals_without_parens: locals_without_parens,
  line_length: 120
]
