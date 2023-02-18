local icons = {}

icons.completion = {
  Class = "",
  Color = "",
  Constant = "",
  Constructor = "",
  Enum = "",
  EnumMember = "",
  Event = "",
  Field = "",
  File = "",
  Folder = "",
  Function = "",
  Interface = "",
  Keyword = "",
  Method = "",
  Module = "",
  Operator = "",
  Property = "",
  Reference = "",
  Snippet = "",
  Struct = "",
  Text = "",
  TypeParameter = "",
  Unit = "",
  Value = "",
  Variable = "",
}

-- stylua: ignore
icons.diagnostic = {
  error = " ", -- nf-fa-times_circle
  warn  = " ", -- nf-fa-exclamation_circle
  info  = " ", -- nf-fa-info_circle
  hint  = " ", -- nf-cod-lightbulb
}

-- stylua: ignore
icons.loglevel = {
  ERROR = "", -- nf-fa-times_circle
  WARN  = "", -- nf-fa-exclamation_circle
  INFO  = "", -- nf-fa-info_circle
  DEBUG = "", -- nf-fa-bug
  TRACE = "✎", -- U+270E
}

-- stylua: ignore
icons.diff = {
  added    = " ", -- nf-fa-plus_square
  modified = " ", -- nf-fa-square
  removed  = " ", -- nf-fa-minus_squarel
}

-- stylua: ignore
icons.file_status = {
  modified = "●", -- U+25CF
  readonly = "", -- nf-fa-lock
  new      = "", -- nf-fa-plus_circle
}

return icons
