return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {
      { "folke/neoconf.nvim", version = "1", cmd = "Neoconf", config = true },
      { "folke/neodev.nvim", version = "2", config = true },
      "hrsh7th/cmp-nvim-lsp",
      "williamboman/mason.nvim",
      {
        "williamboman/mason-lspconfig.nvim",
        opts = {
          automatic_installation = {
            exclude = {
              "julials", -- I use my own config of julials
            },
          },
        },
      },
    },
    config = function()
      require("lspconfig.ui.windows").default_options.border = "rounded"
      require("lsp").setup()
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ui = {
        -- TODO: change size of floating window
        border = "rounded",
        icons = {
          package_installed = "●",
          package_pending = "◉",
          package_uninstalled = "○",
        },
      },
    },
  },
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          local null_ls = require "null-ls"
          local builtins = null_ls.builtins
          null_ls.setup {
            sources = {
              builtins.formatting.stylua,
              builtins.diagnostics.gitlint,
              -- Python
              builtins.diagnostics.flake8,
              builtins.formatting.autopep8,
              builtins.formatting.autoflake,
            },
          }
        end,
      },
    },
    opts = {
      automatic_installation = true,
    },
  },
}
