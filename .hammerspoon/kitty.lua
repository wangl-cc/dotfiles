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

function M.hotkey_win()
  local app = hs.application.get "kitty"

  -- if kitty is not running, launch it
  if not app then
    hs.alert.show "Kitty is not running, please open it manually"
    return
  end

  M.remote_run "launch --type=os-window"
end

function M.bind(mods, key) hs.hotkey.bind(mods, key, M.hotkey_win) end

return M
