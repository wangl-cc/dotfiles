local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        ---@diagnostic disable: missing-fields
        ---@type lspconfig.options.jsonls
        jsonls = {},
        ---@type lspconfig.options.yamlls
        yamlls = {},
        taplo = {},
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
        { type = "formatting", name = "prettier" },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = tbl.merge_options {
      ensure_installed = {
        "json",
        "jsonc",
        "json5",
        "yaml",
        "toml",
      },
    },
  },
}
