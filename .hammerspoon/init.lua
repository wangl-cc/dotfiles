local kitty_bundleID = "net.kovidgoyal.kitty"

hs.hotkey.bind({ "option" }, "space", function()
  local app = hs.application.get(kitty_bundleID)

  if not app then
    app = hs.application.open(kitty_bundleID, 5, true)
  else
    app:selectMenuItem { "Shell", "New OS Window" }
  end
end)
