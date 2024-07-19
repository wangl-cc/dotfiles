local tbl = LDU.tbl
local import = LDU.import

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
        ruff_lsp = {},
        ---@diagnostic enable: missing-fields
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
