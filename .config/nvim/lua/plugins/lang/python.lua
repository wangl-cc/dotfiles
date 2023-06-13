local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        ---@type lspconfig.options.pyright
        pyright = {},
      },
    },
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    optional = true,
    opts = tbl.merge_options {
      ---@type NullLSBuiltinSpec[]
      sources = {
        { type = "formatting", name = "autopep8" },
        { type = "formatting", name = "autoflake" },
        { type = "diagnostics", name = "flake8" },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = tbl.merge_options {
      ensure_installed = {
        "python",
      },
    },
  },
}
