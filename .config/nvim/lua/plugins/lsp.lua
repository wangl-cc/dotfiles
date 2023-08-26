local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "folke/neoconf.nvim", version = "1", cmd = "Neoconf", config = true },
      "hrsh7th/cmp-nvim-lsp",
      "williamboman/mason-lspconfig.nvim",
      "jose-elias-alvarez/null-ls.nvim",
    },
    config = function(_, opts)
      require("lspconfig.ui.windows").default_options.border = "rounded"
      require("lsp").setup(opts)
    end,
  },
  {
    "williamboman/mason.nvim",
    version = "1",
    opts = tbl.merge_options {
      ui = {
        border = "rounded",
        width = 0.8,
        height = 0.8,
        icons = {
          package_installed = "●",
          package_pending = "◉",
          package_uninstalled = "○",
        },
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    version = "1",
    dependencies = { "williamboman/mason.nvim" },
  },
  {
    "jay-babu/mason-null-ls.nvim",
    version = "2",
    dependencies = {
      "williamboman/mason.nvim",
    },
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = {
      "jay-babu/mason-null-ls.nvim",
    },
    config = function(_, opts) require("lsp.null-ls").setup(opts) end,
  },
  {
    "nvim-lualine/lualine.nvim",
    optinal = true,
    opts = tbl.merge_options {
      sections = {
        lualine_b = {
          {
            function() return "󰁨" end,
            ---@diagnostic disable-next-line: undefined-field
            cond = function() return vim.b.autofmt end,
          },
        },
      },
    },
  },
}
