return {
  {
    "echasnovski/mini.align",
    name = "mini.align",
    keys = {
      { "ga", desc = "Align code", mode = { "v", "n" } },
      { "gA", desc = "Align code with preview", mode = { "v", "n" } },
    },
    opts = { silent = true },
  },
  {
    "echasnovski/mini.jump",
    name = "mini.jump",
    event = "VeryLazy",
  },
  {
    "echasnovski/mini.ai",
    name = "mini.ai",
    event = "VeryLazy",
  },
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
    "echasnovski/mini.comment",
    name = "mini.comment",
    keys = {
      { "gc", desc = "Toggle comment linewise", mode = { "v", "n" } },
    },
    opts = {},
  },
  {
    "echasnovski/mini.bufremove",
    name = "mini.bufremove",
  },
  {
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
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
      require("cmp").event:on(
        "confirm_done",
        require("nvim-autopairs.completion.cmp").on_confirm_done()
      )
    end,
  },
}
