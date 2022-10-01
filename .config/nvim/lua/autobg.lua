-- shortcuts for the most common functions
local o = vim.o
local fn = vim.fn
local env = vim.env
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local doautocmd = vim.api.nvim_exec_autocmds

local auto_bg_lock = false
local is_sshr = env.SSHR_PORT ~= nil
local cmd_core = 'defaults read -g AppleInterfaceStyle'
local cmd_full
if is_sshr then
  cmd_full = { 'ssh', env.LC_HOST, '-o', 'StrictHostKeyChecking=no', '-p', env.SSHR_PORT, cmd_core }
else
  cmd_full = vim.fn.split(cmd_core)
end

local function auto_bg()
  if not auto_bg_lock and
      (fn.has('mac') or (is_sshr and env.LC_OS == 'Darwin')) then
    auto_bg_lock = true
    if fn.system(cmd_full) == 'Dark\n' then
      if o.background ~= 'dark' then
        o.background = 'dark'
        doautocmd('OptionSet', { pattern = 'background' })
      end
    else
      if o.background ~= 'light' then
        o.background = 'light'
        doautocmd('OptionSet', { pattern = 'background' })
      end
    end
    auto_bg_lock = false
  end
end

local id_auto_bg = augroup('AutoBackground', { clear = true })
autocmd('Signal', {
  pattern = 'SIGWINCH', callback = auto_bg, group = id_auto_bg
})

return auto_bg

-- vim:tw=76:ts=2:sw=2:et
