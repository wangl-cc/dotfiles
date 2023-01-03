return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {
      { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
      { "folke/neodev.nvim", config = true },
      "hrsh7th/cmp-nvim-lsp",
      "williamboman/mason.nvim",
      {
        "williamboman/mason-lspconfig.nvim",
        config = {
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
    config = {
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
    "jose-elias-alvarez/null-ls.nvim",
    event = "BufReadPre",
    dependencies = {
      "williamboman/mason.nvim",
      {
        "jayp0521/mason-null-ls.nvim",
        config = {
          ensure_installed = { "stylua", "gitlint" },
        },
      },
    },
    config = function()
      local null_ls = require "null-ls"
      null_ls.setup {
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.diagnostics.gitlint,
        },
      }
    end,
  },
}
