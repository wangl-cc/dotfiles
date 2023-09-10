local tbl = require "util.table"
local icons = require "util.icons"

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
        icons = icons.package,
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
    "akinsho/bufferline.nvim",
    optional = true,
    opts = tbl.merge_options {
      ---@diagnostic disable: missing-fields
      ---@type bufferline.Options
      options = {
        custom_areas = {
          right = function()
            ---@diagnostic disable-next-line: undefined-field
            local autofmt = vim.b.autofmt
            local msgs = {
              { text = " Format ", link = "DiagnosticInfo" },
              { text = "", link = "DiagnosticOk" },
              { text = "", link = "DiagnosticWarn" },
            }
            if autofmt then
              msgs[2].text = "  "
            else
              msgs[3].text = "  "
            end
            return msgs
          end,
        },
      },
      ---@diagnostic enable: missing-fields
    },
  },
  -- Auto trigger signature help
  {
    "ray-x/lsp_signature.nvim",
    opts = tbl.merge_options {
      bind = true,
      noice = true,
      handler_opts = {
        border = "rounded",
      },
    },
  },
}
