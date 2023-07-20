local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        rust_analyzer = {
          ---@type lspconfig.options.rust_analyzer
          options = {},
        },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = tbl.merge_options {
      ensure_installed = {
        "rust",
      },
    },
  },
}
