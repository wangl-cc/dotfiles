local tbl = require "util.table"

return {
  {
    "lervag/vimtex",
    ft = "tex",
    cmd = "VimtexInverseSearch", -- for inverse search
    config = function()
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_reading_bar = 1
    end,
  },
  {
    "neovim/nvim-lspconfig",
    optional = true,
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        ---@diagnostic disable: missing-fields
        texlab = {},
        typst_lsp = {},
        ltex = {
          ---@type lspconfig.options.ltex
          options = {
            autostart = false,
            filetypes = { "plaintex", "tex", "bib", "markdown", "rst" },
          },
        },
        ---@diagnostic enable: missing-fields
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = tbl.merge_options {
      ignore_install = {
        "latex",
      },
    },
  },
}
