local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        ---@type lspconfig.options.jsonls
        jsonls = {},
        ---@type lspconfig.options.yamlls
        yamlls = {},
        taplo = {},
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
