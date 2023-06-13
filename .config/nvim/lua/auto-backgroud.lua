--[[
Set background automatically based on system theme.
Only works for iTerm2 which send SIGWINCH when theme changes.
--]]
local tbl = require "util.table"

local M = {}

---@alias BackgroundEnum `light` | `dark`

---@param bg BackgroundEnum
local function switch_bg(bg)
  if vim.o.background ~= bg then vim.o.background = bg end
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
  if switcher.pre then switcher.pre() end
  switch_bg(bg)
  if switcher.post then switcher.post() end
end

-- TODO: query background color with OSC 11
-- Currently only handler is implemented OK
-- but I don't know how to get the response in lua
-- Advantages:
-- 1. Works not only macOS but any terminal that supports OSC 11,
-- 2. The response can be get over ssh without remote forwarding.
-- Disadvantages:
-- 1. I can't get the response in lua Currently,
-- 2. We might wait for a short time to get the response, which might be run
--   asynchronously.

-- This is inspired by neovim's implementation of background handler
-- https://github.com/neovim/neovim/blob/06aed7c1776e9db769c77ce836c1995128a6afc6/src/nvim/tui/input.c#L568

--[[
---@param resp string OSC 11 response string
---@return boolean Whether the background is dark
local handle_osc11 = function(resp)
  local rgb = { 0, 0, 0 }
  local rgbmax = { 0, 0, 0 }
  local component = 0
  local i = 1
  local shift = 0
  while true do
    local c = resp:sub(i, i)
    if c == "/" then
      if component == 0 then
        return true -- not a valid OSC 11 response
      end
      component = component + 1
    elseif c == "r" then
      if resp:sub(i, i + 2) == "rgb" then
        i = i + 3
        if resp:sub(i, i) == "a" then i = i + 1 end
      end
      if resp:sub(i, i) == ":" then
        i = i + 1
        component = 1
      end
    elseif component == 4 then
      break -- we don't need alpha
    elseif c == "" then -- end of string
      if component == 0 then
        return true -- not a valid OSC 11 response
      else
        break
      end
    elseif component > 0 then -- must be the last branch in the if-elseif chain
      shift = shift + 1
      if shift > 4 then
        break -- ignore trailing characters
      end
      rgb[component] = bit.bor(bit.lshift(rgb[component], 4), tonumber(c, 16))
      rgbmax[component] = bit.bor(bit.lshift(rgbmax[component], 4), 0xf)
    end
    i = i + 1
  end
  local r = rgb[1] / rgbmax[1]
  local g = rgb[2] / rgbmax[2]
  local b = rgb[3] / rgbmax[3]
  -- Calculate luminance
  local l = 0.299 * r + 0.587 * g + 0.114 * b
  return l < 0.5
end

--[[ Test
print(handle_osc11 "\x1b]11;rgb:24e2/2807/39c2") -- true
print(handle_osc11 "\x1b]11;rgb:e20e/e2d9/e771") -- false
]]

--]]

---@class AutoBackgroundOptions
---@field is_dark fun(): boolean A function to check if system theme is dark
---@field dark? BackgroundSwitcher Switcher options for dark theme
---@field light? BackgroundSwitcher Switcher options for light theme

---@type AutoBackgroundOptions
M.options = {}

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

M.timer = nil

---@param opts AutoBackgroundOptions
function M.setup(opts)
  opts = opts or {}

  tbl.merge(M.options, opts)

  -- Use OSC 11 to check background color if is_dark is not provided
  -- if not M.options.is_dark then
  -- M.options.is_dark = function() return handle_osc11(get_osc11()) end
  -- end

  -- After 2448816 and 43e8ec9, the TUI becomes external process
  -- which means we can't get SIGWINCH from nvim,
  -- so we use a timer to check theme periodically
  if M.timer then M.timer:stop() end
  M.timer = vim.loop.new_timer()
  if not M.timer then error "Failed to create timer" end
  M.timer:start(5000, 5000, vim.schedule_wrap(M.autobg))
end

return M

-- vim:tw=76:ts=2:sw=2:et
