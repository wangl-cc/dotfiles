local M = {
  "folke/tokyonight.nvim",
  version = "1",
  lazy = false,
  priority = 1000,
}

function M.config()
  local is_sshr = vim.env.SSHR_PORT ~= nil
  local cmd_core = "defaults read -g AppleInterfaceStyle"
  local cmd_full
  if is_sshr then
    cmd_full = {
      "ssh",
      vim.env.LC_HOST,
      "-o",
      "StrictHostKeyChecking=no",
      "-p",
      vim.env.SSHR_PORT,
      cmd_core,
    }
  else
    cmd_full = vim.fn.split(cmd_core)
  end

  local function is_dark()
    return vim.fn.systemlist(cmd_full)[1] == "Dark"
  end

  local tokyonight = require "tokyonight.config"
  tokyonight.setup {
    styles = {
      floats = "transparent",
    },
    sidebars = { "qf" },
    on_highlights = function(hl, c)
      hl.rainbowcol6 = { fg = c.magenta2 }
      hl.WindowPicker = { fg = c.black, bg = c.blue }
      hl.WindowPickerNC = { fg = c.black, bg = c.blue }
    end,
  }
  vim.cmd.colorscheme "tokyonight"
  if vim.fn.has "mac" == 1 or (is_sshr and vim.env.LC_OS == "Darwin") then
    require("auto-backgroud").setup {
      is_dark = is_dark,
    }
  end
end

return M
