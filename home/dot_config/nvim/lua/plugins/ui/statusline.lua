-- FIXME: sometimes, when open cmdline or a floating window,
-- the status line will blink.
-- To reproduce: open a not so small file, then open cmdline with `:`
-- If winbar is disabled, everything is fine, I'm not sure why.
-- Maybe we can use winbar provided by lualine instead of dropbar.nvim.

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
