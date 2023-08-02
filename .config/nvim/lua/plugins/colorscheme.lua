local tbl = require "util.table"

return {
  ---@type LazyPluginSpec
  {
    "wangl-cc/auto-bg.nvim",
    event = "UIEnter",
    build = "make",
    opts = {},
  },
  {
    "folke/tokyonight.nvim",
    version = "2",
    lazy = false,
    priority = 1000,
    opts = tbl.merge_options {
      styles = {
        floats = "transparent",
      },
      sidebars = { "qf" },
      on_highlights = function(hl, c)
        hl.WindowPickerStatusLine = { fg = c.black, bg = c.blue }
        hl.WindowPickerStatusLineNC = { fg = c.black, bg = c.blue }
        hl.WindowPickerWinBar = { fg = c.black, bg = c.blue }
        hl.WindowPickerWinBarNC = { fg = c.black, bg = c.blue }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme "tokyonight"
    end,
  },
}
