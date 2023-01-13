local M = {
  "folke/which-key.nvim",
  version = "1",
  event = "UIEnter",
}

M.config = function()
  local wk = require "which-key"
  wk.setup {
    show_help = false,
    show_keys = false,
    plugins = {
      marks = false,
      registers = false,
      spelling = {
        enabled = true,
      },
    },
    key_labels = {
      ["<CR>"] = "↩",
    },
    popup_mappings = {
      scroll_down = "<c-f>",
      scroll_up = "<c-b>",
    },
  }
  wk.register({
    s = { name = "Search source" },
    g = { name = "Git source" },
    t = { name = "Toggle target" },
    c = { name = "Rename target" },
    h = { name = "Hunk action" },
    w = { name = "Workspace action" },
    p = { name = "Package manager action" },
  }, { prefix = "<leader>" })
end

return M
