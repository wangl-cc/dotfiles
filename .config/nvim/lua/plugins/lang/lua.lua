local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    dependencies = {
      { "folke/neodev.nvim", version = "2", config = true },
    },
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        lua_ls = {
          ---@type lspconfig.options.lua_ls
          options = {
            settings = {
              Lua = {
                telemetry = { enable = false },
                workspace = { checkThirdParty = false },
              },
            },
          },
        },
      },
    },
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    optional = true,
    opts = tbl.merge_options {
      ---@type NullLSBuiltinSpec[]
      sources = {
        { type = "formatting", name = "stylua" },
      },
    },
  },
}
