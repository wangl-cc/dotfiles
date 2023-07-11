local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "folke/neoconf.nvim", version = "1", cmd = "Neoconf", config = true },
      "hrsh7th/cmp-nvim-lsp",
      "williamboman/mason-lspconfig.nvim",
      -- NOTE: `mason-null-ls` is not a derect dependency of this plugin,
      -- but it must load before `null-ls` to work properly,
      "jay-babu/mason-null-ls.nvim",
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
    "williamboman/mason-lspconfig.nvim",
    version = "1",
    dependencies = {
      "williamboman/mason.nvim",
    },
    opts = tbl.merge_options {
      automatic_installation = {},
    },
  },
  {
    "jay-babu/mason-null-ls.nvim",
    version = "2",
    dependencies = {
      "williamboman/mason.nvim",
      "jose-elias-alvarez/null-ls.nvim",
    },
    opts = tbl.merge_options {
      automatic_installation = {},
    },
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    ---@alias NullLSBuiltinType "formatting" | "diagnostics" | "code_actions" | "completion" | "hover"
    ---@alias NullLSBuiltinSpec { type: NullLSBuiltinType, name: string }
    ---@param opts { sources: NullLSBuiltinSpec[] } Additional builtin sources to be added
    config = function(_, opts)
      local null_ls = require "null-ls"
      local builtins = null_ls.builtins
      local sources = {}
      for _, source in ipairs(opts.sources or {}) do
        local builtin = builtins[source.type][source.name]
        if builtin then
          table.insert(sources, builtin)
        else
          vim.notify(
            string.format(
              "Invalid null-ls builtin source: %s.%s",
              source.type,
              source.name
            ),
            vim.log.levels.WARN
          )
        end
      end
      null_ls.setup {
        border = "rounded",
        sources = sources,
      }
    end,
  },
  -- {
  --   "nvim-lualine/lualine.nvim",
  --   optinal = true,
  --   opts = tbl.merge_options {
  --     sections = {
  --       lualine_b = {
  --         {
  --           function() return "󰁨" end, -- TODO: a better icon
  --           cond = function()
  --             -- FIXME: open a nvim without lsp and than open a buffer with lsp
  --             -- will cause an error
  --             return package.loaded.lsp and package.loaded.lsp.autoformat[0]
  --           end,
  --         },
  --       },
  --     },
  --   },
  -- },
}
