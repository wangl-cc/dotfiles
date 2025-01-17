Util.register({
  f = {
    callback = Util.import("conform"):get("format"):closure {
      async = true,
      lsp_fallback = true,
    },
    desc = "Format current buffer",
  },
  tc = { [[<Cmd>TSContextToggle<CR>]], desc = "Toggle treesitter context" },
}, { prefix = "<leader>" })

local lualine = require "putil.lualine"

lualine.registry_extension(
  "mason",
  lualine.util.with_time {
    lualine_a = {
      lualine.util.const_string "MASON",
    },
  }
)

require("putil.catppuccin").add_integrations {
  native_lsp = {
    enabled = true,
    virtual_text = {
      errors = { "italic" },
      hints = { "italic" },
      warnings = { "italic" },
      information = { "italic" },
    },
    underlines = {
      errors = { "underline" },
      hints = { "underline" },
      warnings = { "underline" },
      information = { "underline" },
    },
    inlay_hints = {
      background = false,
    },
  },
  semantic_tokens = true,
  treesitter = true,
  treesitter_context = true,
  rainbow_delimiters = true,
}

local plugins = {
  -- LSP
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "folke/neoconf.nvim", version = "*", cmd = "Neoconf", config = true },
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("lspconfig.ui.windows").default_options.border = "rounded"
      require("putil.lsp").setup()
    end,
  },
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    config = function()
      local ts = require "putil.tree-sitter"
      ---@diagnostic disable: missing-fields
      require("nvim-treesitter.configs").setup {
        auto_install = true,
        ensure_installed = ts.get_langs(),
        highlight = {
          enable = true,
          disable = ts.get_langs_disabled_hl(),
        },
        indent = {
          enable = true,
        },
      }
      ---@diagnostic enable: missing-fields
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      optional = true,
      opts = Util.tbl.merge_options {
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["ab"] = "@block.outer",
              ["ib"] = "@block.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>a"] = "@parameter.inner",
            },
            swap_previous = {
              ["<leader>A"] = "@parameter.inner",
            },
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    cmd = "TSContextToggle",
    opts = {
      enable = false,
    },
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPre", "BufNewFile" },
  },
  -- Format
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    config = function()
      local util = require "putil.formatter"
      require("conform").setup {
        formatters_by_ft = util.get_all_formatters(),
        format_on_save = {
          lsp_fallback = true,
          timeout_ms = 500,
        },
      }
    end,
  },
  -- Lint
  {
    "mfussenegger/nvim-lint",
    config = function()
      local util = require "putil.linter"
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        callback = function(args)
          local bo = vim.bo[args.buf]
          local b = vim.b[args.buf]

          -- Skip linting if the buffer is not a normal buffer
          if bo.buftype ~= "" then return end

          -- If linters are not defined for the buffer,
          -- define them based on the filetype
          if not b.linters then
            ---@type string[]
            local linters = {}
            -- Try to lint with linters defined for the filetype
            local ft_linters = bo.buftype and util.get_linters_by_ft(bo.buftype) or {}
            if ft_linters then Util.list.append(linters, ft_linters) end

            -- Try to lint with linters defined for the file path pattern
            local file = args.file
            local pattern_linters = util.get_linters_by_pattern(file)
            if pattern_linters then Util.list.append(linters, pattern_linters) end

            b.linters = linters
          end

          if not vim.tbl_isempty(b.linters) then
            require("lint").try_lint(b.linters)
          end
        end,
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
      })
    end,
  },
  {
    "williamboman/mason.nvim",
    version = "*",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = Util.tbl.merge_options {
      ui = {
        border = "rounded",
        width = 0.8,
        height = 0.8,
        icons = Util.icons.package,
      },
    },
  },
  -- Mason: used to install lsp, formatters, and linters
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    cmd = { "MasonToolsInstall", "MasonToolsUpdate" },
  },
}

local extra_plugins = require("putil.ft-plugins").get_plugins()

Util.list.append(plugins, extra_plugins)

return plugins
