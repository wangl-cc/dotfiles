local tbl = require "util.table"
local import = require "util.import"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        ---@diagnostic disable: missing-fields
        ---@type lspconfig.options.pyright
        pyright = {},
        ---@diagnostic enable: missing-fields
      },
    },
  },
  {
    "nvimtools/none-ls.nvim",
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
  {
    "hkupty/iron.nvim",
    optional = true,
    opts = tbl.merge_options {
      config = {
        repl_definition = {
          python = import("iron.fts.python"):get("ipython"):tbl(),
        },
      },
    },
  },
}
