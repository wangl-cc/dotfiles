local putil = require "putil.lualine"

return {
  "nvim-lualine/lualine.nvim",
  event = "UIEnter",
  opts = Util.tbl.merge_options {
    options = {
      theme = "auto",
      globalstatus = true,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
    },
    extensions = putil.extensions,
    sections = putil.sections,
  },
}
