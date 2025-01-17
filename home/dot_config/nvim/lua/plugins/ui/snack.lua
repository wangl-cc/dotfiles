local snacks = Util.import "snacks"
local lazygit = snacks:get "lazygit"
local terminal = snacks:get "terminal"

local lualine = require "putil.lualine"

lualine.registry_extension(
  "snacks_terminal",
  lualine.util.with_time {
    lualine_a = { "mode" },
  }
)

require("putil.catppuccin").add_integrations { snacks = true }

-- Terminal keymaps
Util.register({
  ["<leader>gg"] = { lazygit:closure(), desc = "Open lazygit" },
  ["<C-j>"] = {
    terminal:closure(nil, {
      win = {
        height = 0.4,
        width = 0.8,
        row = 0.0,
        position = "float",
        border = {
          "", -- top left corner
          "", -- top border
          "", -- top right corner
          "│", -- right border
          "╯", -- bottom right corner
          "─", -- bottom border
          "╰", -- bottom left corner
          "│", -- left border
        },
      },
    }),
    desc = "Toggle terminal",
    mode = { "n", "i", "t" },
  },
}, { silent = true })

-- A collection of QoL plugins by folke
---@module 'lazy'
---@type LazyPluginSpec
return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 999,
  opts = {
    bigfile = {
      enabled = true,
    },
    indent = {
      enabled = true,
    },
    input = {
      enabled = true,
    },
    notifier = {
      enabled = true,
    },
    quickfile = {
      exclude = { "latex" },
    },
    scroll = {
      enabledw = true,
    },
  },
}
