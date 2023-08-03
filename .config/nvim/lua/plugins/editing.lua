local tbl = require "util.table"

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
    "echasnovski/mini.surround",
    name = "mini.surround",
    keys = {
      { "ys", desc = "Add a surrounding pair" },
      { "cs", desc = "Change a surrounding pair" },
      { "ds", desc = "Delete a surrounding pair" },
    },
    opts = {
      mappings = {
        add = "ys",
        delete = "ds",
        replace = "cs",
      },
    },
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
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      {
        "nvim-lualine/lualine.nvim",
        optinal = true,
        opts = tbl.merge_options {
          sections = {
            lualine_x = {
              {
                function() return require("copilot.api").status.data.status end,
                icon = "",
                icon_enabled = true,
                cond = function()
                  local ok, clients =
                    pcall(vim.lsp.get_active_clients, { name = "copilot", bufnr = 0 })
                  return ok and #clients > 0
                end,
              },
            },
          },
        },
      },
    },
    cmd = "Copilot",
    opts = tbl.merge_options {
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
