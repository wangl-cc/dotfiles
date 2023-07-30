local tbl = require "util.table"

return {
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
      parser_install_dir = vim.fn.stdpath "config",
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
    config = function()
      require("treesitter-context").setup {
        -- set to false at setup,
        -- because it's loaded by TSContextToggle command
        -- and which will toggle this option
        enable = false,
      }
    end,
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPre", "BufNewFile" },
  },
}
