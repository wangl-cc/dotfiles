local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        ---@diagnostic disable: missing-fields
        rust_analyzer = {
          ---@type lspconfig.options.rust_analyzer
          options = {
            settings = {
              ["rust-analyzer"] = {
                diagnostics = {
                  disabled = {
                    "inactive-code",
                  },
                },
              },
            },
          },
        },
        ---@diagnostic enable: missing-fields
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
