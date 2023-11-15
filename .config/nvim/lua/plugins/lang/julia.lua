local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        julials = {
          disabled = vim.env.__JULIA_LSP_DISABLE == "true"
            or vim.fn.executable "julia" == 0,
          autofmt = false,
          ---@type lspconfig.options.julials
          options = {
            ---@diagnostic disable: missing-fields
            settings = {
              julia = {
                lint = {
                  run = true,
                  missingrefs = "all",
                  disabledDirs = { "test", "docs" },
                },
              },
            },
            ---@diagnostic enable: missing-fields
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = tbl.merge_options {
      ensure_installed = {
        "julia",
      },
    },
  },
  {
    "hkupty/iron.nvim",
    optional = true,
    opts = tbl.merge_options {
      config = {
        repl_definition = {
          julia = {
            command = { "julia", "--project" },
          },
        },
      },
    },
  },
}
