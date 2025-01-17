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
icons.diagnostics = {
  error = "󰅚 ", -- nf-md-close_circle_outline
  warn  = "󰗖 ", -- nf-md-alert_circle_outline
  info  = "󰋽 ", -- nf-md-information_outline
  hint  = "󰘥 ", -- nf-md-help_circle_outline
}

-- stylua: ignore
icons.loglevel = {
  ERROR = "󰅚 ", -- nf-md-close_circle_outline
  WARN  = "󰗖 ", -- nf-md-alert_circle_outline
  INFO  = "󰋽 ", -- nf-md-information_outline
  DEBUG = " ", -- nf-fa-bug
  TRACE = " ", -- nf-fac-footprint
}

-- stylua: ignore
icons.diff = {
  added    = "󰐙 ", -- nf-md-plus_circle_outline
  removed  = "󰍷 ", -- nf-md-minus_circle_outline
  modified = "󰝶 ", -- nf-md-pencil_circle_outline
}

-- stylua: ignore
icons.file_status = {
  modified = "󰄯 ", -- nf-md-checkbox_blank_circle
  readonly = "󰌾 ", -- nf-md-lock
  new      = "󰐙 ", -- nf-md-plus_circle_outline
}

-- stylua: ignore
icons.package = {
  package_installed   = "󰪥 ", -- nf-md-circle_slice_8
  package_pending     = "󰻃 ", -- nf-md-record_circle_outline
  package_uninstalled = "󰝦 ", -- nf-md-checkbox_blank_circle_outline
}

return icons
