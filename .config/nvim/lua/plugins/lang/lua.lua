local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
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
                hint = {
                  enable = true,
                },
              },
            },
          },
          ---@diagnostic enable: missing-fields
        },
      },
    },
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    version = "1",
    dependencies = {
      { "Bilal2453/luvit-meta" },
    },
    opts = {
      library = {
        { path = "luvit-meta/library", words = { "vim%.uv" } },
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
