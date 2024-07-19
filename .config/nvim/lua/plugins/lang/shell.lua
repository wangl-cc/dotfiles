local tbl = LDU.tbl

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        ---@diagnostic disable: missing-fields
        ---@type lspconfig.options.bashls
        bashls = {
          options = {
            filetypes = { "sh", "bash" },
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
        "bash",
        "fish",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = tbl.merge_options {
      formatters_by_ft = {
        fish = { "fish_indent" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = tbl.merge_options {
      linters_by_ft = {
        fish = "fish",
      },
    },
  },
}
