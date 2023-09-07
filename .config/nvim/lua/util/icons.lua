local icons = {}

icons.kinds = {
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
  Reference = "󰈇",
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
  hint  = " ", -- nf-fa-check_circle
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
  added    = " ", -- nf-fa-plus_circle
  removed  = " ", -- nf-fa-minus_circle
  modified = " ", -- nf-fa-circle_o
}

-- stylua: ignore
icons.file_status = {
  modified = " ", -- nf-fa-circle
  readonly = " ", -- nf-fa-lock
  new      = " ", -- nf-fa-plus_circle
}

-- stylua: ignore
icons.package = {
  package_installed   = " ", -- nf-fa-circle
  package_pending     = " ", -- nf-fa-dot_circle_o
  package_uninstalled = " ", -- nf-fa-circle_o
}

return icons
