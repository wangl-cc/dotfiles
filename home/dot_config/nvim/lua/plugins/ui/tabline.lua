local bd = Util.import("snacks"):get "bufdelete"
local bf = Util.import "bufferline"
local groups = Util.import "bufferline.groups"
local cycle = bf:get "cycle"

---@type table<string, KeymapSpec>
local buffer_operations = {
  [""] = { "", desc = "buffer operations" },
  d = { bd:closure(), desc = "Delete current buffer" },
  D = { bd:closure { force = true }, desc = "Delete current buffer (force)" },
  p = {
    callback = groups:get("toggle_pin"):closure(),
    desc = "Pin current buffer",
  },
  P = {
    callback = groups:get("action"):closure("ungrouped", "close"),
    desc = "Clear all ungrouped buffers",
  },
  g = { bf:get("pick"):closure(), desc = "Pick a buffer" },
  G = { bf:get("close_with_pick"):closure(), desc = "Pick a buffer to close" },
}

Util.register(buffer_operations, { prefix = "<leader>b", silent = true })

---@type table<string, KeymapSpec>
local buffer_navigation = {
  ["]"] = { cycle:closure(1), desc = "Next buffer" },
  ["["] = { cycle:closure(-1), desc = "Previous buffer" },
}
Util.register(buffer_navigation, { silent = true, suffix = "b" })

return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = "UIEnter",
  ---@diagnostic disable: missing-fields
  opts = Util.tbl.merge_options {
    ---@type bufferline.Options
    options = {
      close_command = bd:closure(),
      right_mouse_command = bd:closure(),
      indicator = { style = "underline" },
      hover = {
        enabled = true,
        delay = 200,
        reveal = { "close" },
      },
      offsets = {
        {
          filetype = "neo-tree",
          text = "File Explorer",
          highlight = "Directory",
          text_align = "center",
        },
      },
    },
  },
  ---@diagnostic enable: missing-fields
  ---@param opts bufferline.UserConfig
  config = function(_, opts)
    local bufferline = require "bufferline"
    bufferline.groups.builtin.pinned.icon = ""
    opts.highlights = require("catppuccin.groups.integrations.bufferline").get()
    bufferline.setup(opts)
  end,
}
