local confirm_quit = Util.import "confirm-quit"

Util.register({
  q = { confirm_quit:get("confirm_quit"):closure(), desc = "Confirm quit" },
  Q = { confirm_quit:get("confirm_quit_all"):closure(), desc = "Confirm quit" },
}, { prefix = "<leader>" })

return {
  { "wakatime/vim-wakatime", event = "VeryLazy" },

  {
    "wangl-cc/im-switch.nvim",
    event = "BufWinEnter",
    dev = true,
    opts = {},
  },

  {
    "yutkat/confirm-quit.nvim",
    event = "CmdlineEnter",
    opts = {},
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    opts = {},
  },
}
