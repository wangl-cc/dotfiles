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
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = tbl.merge_options {
      ---@type NullLSBuiltinSpec[]
      sources = {
        { type = "formatting", name = "stylua" },
      },
    },
  },
}
