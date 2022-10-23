local M = {}

function M.config()
  local is_sshr = vim.env.SSHR_PORT ~= nil
  local cmd_core = 'defaults read -g AppleInterfaceStyle'
  local cmd_full
  if is_sshr then
    cmd_full = { 'ssh', vim.env.LC_HOST, '-o', 'StrictHostKeyChecking=no',
      '-p', vim.env.SSHR_PORT, cmd_core }
  else
    cmd_full = vim.fn.split(cmd_core)
  end

  local function can_autobg()
    return vim.fn.has('mac') == 1 or (is_sshr and vim.env.LC_OS == 'Darwin')
  end

  local function is_dark()
    return vim.fn.systemlist(cmd_full)[1] == 'Dark'
  end

  local tokyonight = require('tokyonight.config')
  tokyonight.setup {
    sidebars = { 'qf' },
    on_highlights = function(hl, c)
      hl.rainbowcol6 = { fg = c.magenta2 }
    end,
  }
  vim.cmd [[colorscheme tokyonight]]
  require('util.autobg').setup {
    can_autobg = can_autobg,
    is_dark = is_dark,
  }
end

return M
