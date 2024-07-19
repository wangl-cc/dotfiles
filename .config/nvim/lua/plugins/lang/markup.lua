local tbl = LDU.tbl

return {
  {
    "lervag/vimtex",
    ft = "tex",
    cmd = "VimtexInverseSearch", -- for inverse search
    config = function()
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_reading_bar = 1
    end,
  },
  {
    "neovim/nvim-lspconfig",
    optional = true,
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        ---@diagnostic disable: missing-fields
        texlab = {},
        typst_lsp = {},
        ---@diagnostic enable: missing-fields
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = tbl.merge_options {
      ensure_installed = {
        "latex",
        "typst",
      },
      highlight = {
        disable = {
          "latex",
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = tbl.merge_options {
      linters_by_ft = {
        markdown = { "markdownlint" },
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    optional = true,
    opts = tbl.merge_options {
      ensure_installed = {
        "markdownlint",
      },
    },
  },
}
