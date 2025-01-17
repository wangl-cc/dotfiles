local snacks = Util.import "snacks"
local lazygit = snacks:get "lazygit"

local lualine = require "putil.lualine"

lualine.registry_extension(
  "snacks_terminal",
  lualine.util.with_time {
    lualine_a = { "mode" },
  }
)

require("putil.catppuccin").add_integrations { snacks = true }

-- TODO: add terminal keymaps

-- Terminal keymaps
Util.register({
  gg = { lazygit:closure(), desc = "Open lazygit" },
}, { prefix = "<leader>", silent = true })

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
    scroll = {
      enabledw = true,
    },
  },
}
