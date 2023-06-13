local tbl = require "util.table"

return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" }, -- Load bofore treesitter is loaded
    dependencies = {
      { "HiPhish/nvim-ts-rainbow2", version = "2" },
      "nvim-treesitter/nvim-treesitter-textobjects",
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
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
      rainbow = {
        enable = true,
        extended_mode = true,
        hlgroups = {
          "rainbowcol1",
          "rainbowcol2",
          "rainbowcol3",
          "rainbowcol4",
          "rainbowcol5",
          "rainbowcol6",
          "rainbowcol7",
        },
      },
      context_commentstring = {
        enable = true,
        enable_autocmd = false,
      },
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
    config = function(_, opts) require("nvim-treesitter.configs").setup(opts) end,
  },
  {
    "nvim-treesitter/playground",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      opts = tbl.merge_options {
        ensure_installed = {
          "query",
        },
        playground = {
          enable = true,
        },
      },
    },
    cmd = "TSPlaygroundToggle",
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
}
