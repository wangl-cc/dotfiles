--[[
This file contains the plugins that change apperence of some api
--]]

return {
  -- Better vim.ui.*
  {
    "stevearc/dressing.nvim",
    event = "UIEnter",
    config = {
      -- vim.ui.input is handled by noice
      input = { enabled = false },
      select = {
        enabled = true,
        backend = { "telescope", "builtin" },
      },
    },
  },
  -- Better vim.notify
  {
    "rcarriga/nvim-notify",
    config = {
      stages = "fade",
      timeout = 3000,
      level = vim.log.levels.INFO,
      icons = {
        ERROR = "",
        WARN = "",
        INFO = "",
        DEBUG = "",
        TRACE = "✎",
      },
    },
  },
  -- Incremental vim.lsp.buf.rename
  {
    "smjonas/inc-rename.nvim",
    event = "UIEnter",
    config = true,
  },
}
