return {
  --- Better vim.ui.*
  {
    "stevearc/dressing.nvim",
    event = "UIEnter",
    config = {
      input = { enabled = false },
      select = {
        enabled = true,
        backend = { "telescope", "builtin" },
      },
    },
  },
  --- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "UIEnter",
    config = {
      char = "▏",
      context_char = "▏",
      show_current_context = true,
      show_current_context_start = true,
    },
  },
  -- Notification popup
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
  -- Incremental rename
  {
    "smjonas/inc-rename.nvim",
    event = "UIEnter",
    config = true,
  },
}
