local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    dependencies = {
      { "folke/neodev.nvim", config = true },
    },
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        lua_ls = {
          ---@diagnostic disable: missing-fields
          ---@type lspconfig.options.lua_ls
          options = {
            settings = {
              Lua = {
                telemetry = { enable = false },
                workspace = { checkThirdParty = false },
              },
            },
          },
          ---@diagnostic enable: missing-fields
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = tbl.merge_options {
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    optional = true,
    opts = tbl.merge_options {
      ensure_installed = {
        "stylua",
      },
    },
  },
}
