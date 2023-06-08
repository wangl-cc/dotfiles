-- hotkey windows for kitty, this not works well as iTerm2 {{{
-- each screen has its own kitty hotkey window
-- ISSUE: we can't get the correct screen in full screen app
-- Maybe we need to use spaces to manage kitty windows instead of screens
-- Besides, in some cases, the hammerspoon can't manage the correct kitty window
local kitty_hotkeywins = {}

local hs_debug = true
local function log(...)
  if not hs_debug then return end
  local arg = { ... }
  for _, v in ipairs(arg) do
    if type(v) == "table" then
      print(hs.inspect(v))
    else
      print(v)
    end
  end
end

hs.hotkey.bind({ "option" }, "space", function()
  local kitty_bundleID = "net.kovidgoyal.kitty"
  local app = hs.application.get(kitty_bundleID)

  local win_pos = hs.geometry.rect(0.2, 0, 0.6, 0.5)

  local current_screen = hs.screen.mainScreen()
  log("current_screen", current_screen, current_screen:id())
  local current_hotkeywin = kitty_hotkeywins[current_screen:id()]
  log("current_hotkeywin", current_hotkeywin)

  -- if kitty is not running, launch it
  if not app then
    app = hs.application.open(kitty_bundleID, 5, true)
    current_hotkeywin = app:mainWindow()
  end

  -- if the window is closed, the title will be an empty string
  -- we need to set kitty_hotkeywin to nil to force a new window
  if
    current_hotkeywin
    and (current_hotkeywin:title() == "" or current_hotkeywin:isMaximized())
  then
    current_hotkeywin = nil
  end

  -- if the hotkey window is not open or has been closed,
  -- open a new window to use as the hotkey window
  if not current_hotkeywin then
    if app:selectMenuItem { "Shell", "New OS Window" } then
      while not current_hotkeywin do
        log "Waiting for kitty window"
        hs.timer.usleep(100000)
        local wins = app:allWindows()
        for _, win in ipairs(wins) do
          local title = win:title()
          -- the title of new open windows is "~"
          if title == "~" then
            kitty_hotkeywins[current_screen:id()] = win
            current_hotkeywin = win
            current_hotkeywin:moveToScreen(current_screen)
            current_hotkeywin:moveToUnit(win_pos)
            log(
              "Created kitty window",
              current_hotkeywin,
              current_hotkeywin:id(),
              current_hotkeywin:title()
            )
            return
          end
        end
      end
    else
      hs.alert.show "Could not create kitty window"
      return
    end
  end
  -- if the current window is not the hotkey window, focus it, otherwise, hide it
  local current_win = hs.window.focusedWindow()
  if not current_win or current_win:id() ~= current_hotkeywin:id() then
    log("Focusing kitty window", current_hotkeywin:id())
    current_hotkeywin:moveToScreen(current_screen)
    current_hotkeywin:moveToUnit(win_pos)
    current_hotkeywin:focus()
  else
    log("Hiding kitty window", current_hotkeywin:id())
    current_hotkeywin:minimize()
  end
end)
--}}}
