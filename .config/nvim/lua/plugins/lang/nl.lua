local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = tbl.merge_options {
      ---@type table<string, LspConfig>
      servers = {
        harper_ls = {
          options = {
            filetypes = {
              "latex",
              "markdown",
              "typst",
              "toml",
              "gitcommit",
            },
          },
        },
      },
    },
  },
}
