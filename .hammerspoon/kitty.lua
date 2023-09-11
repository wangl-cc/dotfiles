local M = {}

M.bin = "/Applications/kitty.app/Contents/MacOS/kitty"

M.remote_cmd = M.bin .. " @ --to unix:/tmp/kitty"

M.window_title = "Hotkey"

---@param cmd string|table
---@return string
function M.remote_run(cmd)
  if type(cmd) == "string" then
    cmd = M.remote_cmd .. " " .. cmd
  elseif type(cmd) == "table" then
    cmd = M.remote_cmd .. " " .. table.concat(cmd, " ")
  else
    error("Invalid cmd type: " .. type(cmd))
  end
  local output, status = hs.execute(cmd)
  if not status then hs.alert.show("Failed to run command: " .. cmd) end
  ---@cast output string
  return output
end

function M.all_windows() return hs.window.filter.new({ kitty = {} }):getWindows() end

---@param wins hs.window[]|nil
---@return hs.window|nil
function M.find_hotkeywin(wins)
  if not wins then wins = M.all_windows() end
  for _, win in ipairs(wins) do
    if win:title() == M.window_title then return win end
  end
  return nil
end

function M.hotkey_win()
  local app = hs.application.get "kitty"

  -- if kitty is not running, launch it
  if not app then
    hs.alert.show "Kitty is not running, please open it manually"
    return
  end

  local current_screen = hs.mouse.getCurrentScreen()

  local id = (M.remote_run "launch --type=os-window"):sub(1, -2) -- remove the last \n
  local current_hotkeywin = nil
  local count = 0
  while not current_hotkeywin do
    if count > 10 then
      hs.alert.show "Failed to get hotkey window"
      return
    end
    hs.timer.usleep(100000) -- 100ms
    count = count + 1
    M.remote_run {
      "set-window-title",
      "--match=id:" .. id,
      "--temporary",
      M.window_title,
    }
    current_hotkeywin = M.find_hotkeywin()
  end

  if current_hotkeywin:isFullScreen() then current_hotkeywin:toggleFullScreen() end

  -- Move the hotkey window to the current screen and focus it
  current_hotkeywin:moveToScreen(current_screen)
  current_hotkeywin:focus()
end

function M.bind(mods, key) hs.hotkey.bind(mods, key, M.hotkey_win) end

return M
