return {
  {
    "kylechui/nvim-surround",
    keys = {
      { "ys", desc = "Add a surrounding pair" },
      { "cs", desc = "Change a surrounding pair" },
      { "ds", desc = "Delete a surrounding pair" },
    },
    opts = {},
  },
  {
    "folke/ts-comments.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      local cond = require "nvim-autopairs.conds"
      local before_char = function(char)
        return function(opts) return opts.prev_char == char end
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
    end,
  },
}
