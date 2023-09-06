local M = {}

M.bin = "/Applications/kitty.app/Contents/MacOS/kitty"

M.indicator = { char = "📌", byte_len = 4 }

M.geometry = hs.geometry.rect(0.15, 0, 0.7, 0.4)

function M.match_win(win)
  local title = win:title()
  if title:sub(1, M.indicator.byte_len) == M.indicator.char then return true end
  return false
end

function M.all_windows() return hs.window.filter.new({ kitty = {} }):getWindows() end

---@param wins hs.window[]
---@return hs.window|nil
function M.find_hotkeywin(wins)
  for _, win in ipairs(wins) do
    if M.match_win(win) then return win end
  end
end

function M.new_hotkeywin()
  return hs.execute(
    M.bin .. " @ --to unix:/tmp/kitty launch --type=os-window --env KITTY_HOTKEYWIN=1"
  )
end

function M.hotkey_win()
  local app = hs.application.get "kitty"

  -- if kitty is not running, launch it
  if not app then
    hs.alert.show "Kitty is not running, please open it manually"
    return
  end

  local current_screen = hs.mouse.getCurrentScreen()
  -- if the focused window is kitty hotkey window, minimize it
  local focused_win = hs.window.focusedWindow()
  if focused_win and M.match_win(focused_win) then
    local focused_screen = focused_win:screen()
    if focused_screen ~= current_screen then
      focused_win:moveToScreen(current_screen)
    else
      focused_win:minimize()
    end
    return
  end

  local wins = M.all_windows()
  print("Get wins", hs.inspect(wins))
  -- Otherwise, find the hotkey window
  local current_hotkeywin = M.find_hotkeywin(wins)

  -- if the hotkey window is not found, create a new one
  if not current_hotkeywin then
    M.new_hotkeywin()
    while not current_hotkeywin do
      hs.timer.usleep(100000) -- 100ms
      wins = M.all_windows()
      print("Get wins in sleep", hs.inspect(wins))
      current_hotkeywin = M.find_hotkeywin(wins)
    end
  end

  if current_hotkeywin:isFullScreen() then current_hotkeywin:toggleFullScreen() end

  -- Move the hotkey window to the current screen and focus it
  current_hotkeywin:move(M.geometry, current_screen)
  current_hotkeywin:focus()
end

-- M.filter = hs.window.filter.new {
--   kitty = { allowTitles = M.indicator.char },
-- }
--
-- ---@param win hs.window
-- M.auto_minimize = function(win, name, event)
--   print "windowUnfocused"
--   if not win:isMinimized() then win:minimize() end
-- end

function M.bind(mods, key)
  hs.hotkey.bind(mods, key, M.hotkey_win)
  -- minimize the hotkey window when it loses focus
  -- M.filter:subscribe(hs.window.filter.windowFocused, M.auto_minimize)
end

return M
