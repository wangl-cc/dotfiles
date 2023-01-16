--[[
This file is a modified version of s1n7ax/nvim-window-picker
URL: https://github.com/s1n7ax/nvim-window-picker
License: MIT, full license text see bottom of this file
--]]
local ui = require "util.ui"
local tbl = require "util.table"

local M = {}

---@class FilterRule
---@field current? boolean Filter out current window or not
---@field bo? table<string, string[]> Buffer options to be filtered out
---@field wo? table<string, string[]> Window options to be filtered out
---@field func? fun(winid:integer):boolean Function to filter out windows

---@class WindowPickerOptions
---@field autoselect_one? boolean
---@field chars? string
---@field use_winbar?  0 | 1 | 2
---@field filter_rule? FilterRule

---@type WindowPickerOptions
M.options = {
  autoselect_one = true,
  chars = "FJDKSLA;CMRUEIWOQP",
  use_winbar = 0, -- 0: never | 1: when cmdheight == 0 | 2: always
  filter_rule = {
    current = false,
    wo = {},
    bo = {
      filetype = { "neo-tree" },
      buftype = { "terminal" },
    },
  },
}

---@param windows integer[] Window ids to be filtered
---@param rule FilterRule Filter rule
---@return integer[] Filtered window ids
local function filter_windows(windows, rule)
  -- remove current window firstly if needed
  if not rule.current then
    local current = vim.api.nvim_get_current_win()
    for i, winid in ipairs(windows) do
      if winid == current then
        table.remove(windows, i)
        break
      end
    end
  end
  -- window option filter
  if rule.wo and vim.tbl_count(rule.wo) > 0 then
    windows = vim.tbl_filter(function(winid)
      for opt, blacklist in pairs(rule.wo) do
        local val = vim.api.nvim_win_get_option(winid, opt)
        if vim.tbl_contains(blacklist, val) then
          return false
        end
      end
      return true
    end, windows)
  end
  -- buffer option filter
  if rule.bo and vim.tbl_count(rule.bo) > 0 then
    windows = vim.tbl_filter(function(winid)
      local buffer = vim.api.nvim_win_get_buf(winid)
      for opt, blacklist in pairs(rule.bo) do
        local val = vim.api.nvim_buf_get_option(buffer, opt)
        if vim.tbl_contains(blacklist, val) then
          return false
        end
      end
      return true
    end, windows)
  end
  -- apply custom filter function
  if rule.func then
    windows = vim.tbl_filter(rule.func, windows)
  end
  return windows
end

local function picker_hl(indicator_hl)
  return indicator_hl .. ":WindowPicker," .. indicator_hl .. "NC:WindowPickerNC"
end

---@param opts? WindowPickerOptions Options to override default options
---@return integer|nil Selected window id or nil if no window is selected
function M.pick_window(opts)
  -- merge options
  local options = vim.tbl_extend("force", M.options, opts or {})
  local rules = options.filter_rule
  local chars = options.chars

  -- Get windows to pick
  -- get all windows in current tabpage
  local windows = vim.api.nvim_tabpage_list_wins(0)
  -- remove floating windows
  windows = vim.tbl_filter(function(winid)
    local config = vim.api.nvim_win_get_config(winid)
    return config.relative == "" -- empty string means not floating
  end, windows)
  -- filter windows by rules
  local pickables = filter_windows(windows, rules)
  -- If there are no selectable windows, return
  if #pickables == 0 then
    return
  end
  -- If there is only one selectable window and autoselect_one is true, return it
  if options.autoselect_one and vim.tbl_count(pickables) == 1 then
    return pickables[1]
  end

  -- Setup UI to indicate windows
  -- check if use winbar
  local use_winbar = options.use_winbar
  if vim.opt.cmdheight:get() == 0 then
    use_winbar = use_winbar + 1
  end
  -- winbar or statusline variables
  local laststatus
  local cmdheight
  local indicator
  local indicator_hl
  -- setup winbar or statusline
  if use_winbar < 2 then -- don't use winbar
    laststatus = vim.o.laststatus
    cmdheight = vim.o.cmdheight
    indicator = "statusline"
    indicator_hl = "StatusLine"
    -- set statusline and cmdheight to show indicator
    vim.o.laststatus = 2
    vim.o.cmdheight = 1
  else
    indicator = "winbar"
    indicator_hl = "WinBar"
  end
  -- setup indicator for selectable windows
  local chars_used = {}
  local win_opts = {}

  for i, id in ipairs(pickables) do
    local char = chars:sub(i, i)
    assert(char ~= "", "Not enough chars to indicate windows")
    table.insert(chars_used, char)
    -- save window options
    win_opts[id] = {
      [indicator] = vim.api.nvim_win_get_option(id, indicator),
      winhl = vim.api.nvim_win_get_option(id, "winhl"),
    }
    -- set indicator to show char
    vim.api.nvim_win_set_option(id, indicator, "%=" .. char .. "%=")
    vim.api.nvim_win_set_option(id, "winhl", picker_hl(indicator_hl))
  end
  -- redraw windows
  vim.cmd.redraw()

  -- ask user to pick a window, user type <Esc> means no window selected
  local _, i = ui.confirm(chars_used, { prompt = "Pick a window" })

  -- Restore UI
  -- restore window options
  for _, id in ipairs(pickables) do
    if vim.api.nvim_win_is_valid(id) then
      for opt, value in pairs(win_opts[id]) do
        vim.api.nvim_win_set_option(id, opt, value)
      end
    end
  end
  -- restore laststatus and cmdheight
  if use_winbar < 2 then
    vim.o.laststatus = laststatus
    vim.o.cmdheight = cmdheight
  end

  -- return selected window id, i2id[0] is nil which means no window selected
  return pickables[i]
end

---@param opts WindowPickerOptions Options to override default options
M.setup = function(opts)
  tbl.extend_inplace(M.options, opts)
end

return M

--[[
> MIT License

> Copyright (c) 2021 s1n7ax

> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:

> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.

> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.
--]]
