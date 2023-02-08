return {
  -- TODO: Noice route for mini.align and jump
  {
    "echasnovski/mini.align",
    keys = { "ga", "gA" },
    config = function()
      require("mini.align").setup {}
    end,
  },
  {
    "echasnovski/mini.jump",
    event = "VeryLazy",
    config = function()
      require("mini.jump").setup {}
    end,
  },
  {
    "kylechui/nvim-surround",
    keys = { "ys", "ds", "cs" },
    config = function()
      require("nvim-surround").setup {}
    end,
  },
  {
    "numToStr/Comment.nvim",
    keys = { "gc", "gb" },
    config = function()
      require("Comment").setup {
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      }
    end,
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      local cond = require "nvim-autopairs.conds"
      local before_char = function(char)
        return function(opts)
          return opts.prev_char == char
        end
      end
      npairs.setup {}
      npairs.add_rules {
        -- Add spaces after brackets
        Rule(" ", " "):with_pair(function(opts)
          local pair = opts.line:sub(opts.col - 1, opts.col)
          return vim.tbl_contains({ "()", "[]", "{}" }, pair)
        end),
        Rule("( ", " )")
          :with_pair(cond.none())
          :with_move(before_char " )")
          :use_key ")",
        Rule("[ ", " ]")
          :with_pair(cond.none())
          :with_move(before_char " ]")
          :use_key "]",
        Rule("{ ", " }")
          :with_pair(cond.none())
          :with_move(before_char " }")
          :use_key "}",
        -- $ for LaTeX
        Rule("$", "$", { "tex", "latex" }):with_move(before_char "$"),
      }
      require("cmp").event:on(
        "confirm_done",
        require("nvim-autopairs.completion.cmp").on_confirm_done()
      )
    end,
  },
  {
    "zbirenbaum/copilot.lua",
    opts = {
      filetypes = {
        help = false,
        iron = false,
        toggleterm = false,
        ["*"] = true,
      },
      panel = {
        enabled = false,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
      },
    },
  },
}
