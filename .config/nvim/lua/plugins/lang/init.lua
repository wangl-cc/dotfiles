local tbl = require "util.table"
local icons = require "util.icons"

return {
  -- Mason: used to install lsp, formatters, and linters
  {
    "williamboman/mason.nvim",
    version = "1",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
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
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    cmd = { "MasonToolsInstall", "MasonToolsUpdate" },
  },
  -- LSP
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "folke/neoconf.nvim", version = "1", cmd = "Neoconf", config = true },
      "hrsh7th/cmp-nvim-lsp",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function(_, opts)
      require("lspconfig.ui.windows").default_options.border = "rounded"
      require("lsp").setup(opts)
    end,
  },
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    opts = tbl.merge_options {
      ensure_installed = {
        "vim",
        "vimdoc",
        "diff",
        "embedded_template",
      },
      auto_install = true,
      highlight = {
        enable = true,
      },
      indent = {
        enable = false,
      },
    },
    config = function(_, opts)
      opts.ensure_installed = tbl.unique(opts.ensure_installed or {})
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      optional = true,
      opts = tbl.merge_options {
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
    opts = tbl.merge_options {
      formatters_by_ft = {
        ["_"] = { "trim_whitespace" },
      },
      format_on_save = {
        lsp_fallback = true,
        timeout_ms = 500,
      },
    },
  },
  -- Lint
  {
    "mfussenegger/nvim-lint",
    dependencies = {
      "williamboman/mason.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function(_, opts)
      local custom_linters = opts.custom_linters or {}
      for name, linter in pairs(custom_linters) do
        if linter.parser_from_pattern then
          linter.parser =
            require("lint.parser").from_pattern(unpack(linter.parser_from_pattern))
          linter.parser_from_pattern = nil
        end
        require("lint").linters[name] = linter
      end

      local linters_by_ft = opts.linters_by_ft or {}
      for ft, ft_linter_opts in pairs(linters_by_ft) do
        if type(ft_linter_opts) == "string" then
          -- linter_opts is a single linter
          linters_by_ft[ft] = { linters = { ft_linter_opts } }
        elseif type(ft_linter_opts) == "table" and vim.islist(ft_linter_opts) then
          -- linter_opts is a list of linters
          linters_by_ft[ft] = { linters = ft_linter_opts }
        end
      end
      local linters_by_filepattern = opts.linters_by_filepattern or {}
      for pattern, pattern_linter_opts in pairs(linters_by_filepattern) do
        if type(pattern_linter_opts) == "string" then
          -- linter_opts is a single linter
          linters_by_filepattern[pattern] = { linters = { pattern_linter_opts } }
        elseif
          type(pattern_linter_opts) == "table" and vim.islist(pattern_linter_opts)
        then
          -- linter_opts is a list of linters
          linters_by_filepattern[pattern] = { linters = pattern_linter_opts }
        end
      end

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
            local ft_opts = linters_by_ft[bo.filetype] or {}
            if ft_opts.linters then tbl.append(linters, ft_opts.linters) end
            local no_typo = ft_opts.no_typo

            -- Try to lint with linters defined for the file path pattern
            local file = args.file
            for pattern, pattern_opts in pairs(linters_by_filepattern) do
              if file:match(pattern) and pattern_opts.linters then
                tbl.append(linters, pattern_opts.linters)
                if pattern_opts.no_typo then no_typo = true end
              end
            end

            -- If no_typo is not set, try to lint with typos
            if not no_typo then table.insert(linters, "typos") end

            b.linters = linters
          end

          if not vim.tbl_isempty(b.linters) then
            require("lint").try_lint(b.linters)
          end
        end,
        group = vim.api.nvim_create_augroup("nvim-line", { clear = true }),
      })
    end,
  },
}
