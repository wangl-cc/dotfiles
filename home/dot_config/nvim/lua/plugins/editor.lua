require("putil.catppuccin").add_integrations {
  which_key = true,
  lsp_trouble = true,
  grug_far = true,
}

local trouble = Util.import "trouble"
local toggle = trouble:get "toggle"

Util.register({
  [""] = { "", desc = "toggle trouble" },
  x = {
    callback = toggle:closure "last",
    desc = "Toggle last trouble",
  },
  d = {
    callback = toggle:closure "diagnostics",
    desc = "Toggle diagnostics",
  },
  t = {
    callback = toggle:closure "todo",
    desc = "Toggle todos",
  },
}, { prefix = "<leader>x" })

return {
  -- Incremental vim.lsp.buf.rename
  {
    "smjonas/inc-rename.nvim",
    event = "UIEnter",
    opts = {},
  },
  -- search/replace in multiple files
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = { headerMaxWidth = 80 },
  },
  {
    "folke/todo-comments.nvim",
    version = "*",
    event = "UIEnter",
    opts = {},
  },
  {
    "folke/which-key.nvim",
    version = "*",
    event = "UIEnter",
    opts = {
      icons = {
        rules = false,
        mappings = false,
      },
    },
  },
  {
    "folke/trouble.nvim",
    version = "*",
    cmd = { "Trouble", "TroubleToggle" },
    opts = {
      auto_jump = true,
      focus = true,
    },
  },
}
