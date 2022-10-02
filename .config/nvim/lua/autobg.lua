-- shortcuts for the most common functions
local o = vim.o
local fn = vim.fn
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local doautocmd = vim.api.nvim_exec_autocmds

local M = {}

function M.setup(opts)
  opts = opts or {}

  local can_autobg = opts.can_autobg or function()
    return fn.has('mac') == 1
  end
  local is_dark = opts.is_dark or function()
    return fn.systemlist('defaults read -g AppleInterfaceStyle')[1] == 'Dark'
  end

  local dark_pre = opts.dark and opts.dark.pre
  local dark_post = opts.dark and opts.dark.post
  local light_pre = opts.light and opts.light.pre
  local light_post = opts.light and opts.light.post

  local autobg_lock = false
  local function autobg()
    if not autobg_lock and can_autobg() then
      autobg_lock = true
      if is_dark() then
        if dark_pre then dark_pre() end
        if o.background ~= 'dark' then
          o.background = 'dark'
          doautocmd('OptionSet', { pattern = 'background' })
        end
        if dark_post then dark_post() end
      else
        if light_pre then light_pre() end
        if o.background ~= 'light' then
          o.background = 'light'
          doautocmd('OptionSet', { pattern = 'background' })
        end
        if light_post then light_post() end
      end
      autobg_lock = false
    end
  end

  local autobg_group = augroup('AutoBackground', { clear = true })
  -- iTerm2 will send a SIGWINCH when the theme changes
  autocmd('Signal', {
    pattern = 'SIGWINCH', callback = autobg, group = autobg_group
  })

  return autobg, autobg_group
end

return M

-- vim:tw=76:ts=2:sw=2:et
