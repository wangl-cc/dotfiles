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
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = tbl.merge_options {
      formatters_by_ft = {
        json = { "prettierd" },
        jsonc = { "prettierd" },
        json5 = { "prettierd" },
        yaml = { "prettierd" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = tbl.merge_options {
      linters_by_filepattern = {
        ["%.github/workflows/.+%.ya?ml"] = "actionlint",
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    optional = true,
    opts = tbl.merge_options {
      ensure_installed = {
        "prettierd",
        "actionlint",
      },
    },
  },
}
