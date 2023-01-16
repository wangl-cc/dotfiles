--[[
Set background automatically based on system theme.
Only works for iTerm2 which send SIGWINCH when theme changes.
--]]

local M = {}

---@alias BackgroundEnum `light` | `dark`

---@param bg BackgroundEnum
local function switch_bg(bg)
  if vim.o.background ~= bg then
    vim.o.background = bg
  end
end

---@class BackgroundSwitcher
---@field pre? fun() Pre switch callback
---@field post? fun() Post switch callback

---@param bg BackgroundEnum Background to switch to
---@param switcher? BackgroundSwitcher Switcher options
local function switch(bg, switcher)
  if not switcher then
    switch_bg(bg)
    return
  end
  if switcher.pre then
    switcher.pre()
  end
  switch_bg(bg)
  if switcher.post then
    switcher.post()
  end
end

---@class AutoBackgroundOptions
---@field is_dark fun(): boolean A function to check if system theme is dark
---@field dark? BackgroundSwitcher Switcher options for dark theme
---@field light? BackgroundSwitcher Switcher options for light theme

local autobg_lock = false
function M.autobg()
  if not autobg_lock then
    autobg_lock = true
    if M.options.is_dark() then
      switch("dark", M.options.dark)
    else
      switch("light", M.options.light)
    end
    autobg_lock = false
  end
end

---@param opts AutoBackgroundOptions
function M.setup(opts)
  opts = opts or {}

  M.options = vim.deepcopy(opts)

  local autobg_group = vim.api.nvim_create_augroup("AutoBackground", { clear = true })
  -- iTerm2 will send a SIGWINCH when the theme changes
  vim.api.nvim_create_autocmd("Signal", {
    pattern = "SIGWINCH",
    callback = M.autobg,
    group = autobg_group,
    nested = true,
  })

  return autobg_group
end

return M

-- vim:tw=76:ts=2:sw=2:et