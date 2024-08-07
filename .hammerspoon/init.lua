-- hs.loadSpoon "EmmyLua"

hs.application.enableSpotlightForNameSearches(true)

---@alias Modifier
---| '"cmd"'
---| '"ctrl"'
---| '"option"'
---| '"shift"'

---@param key string The key to bind
---@param fn function The function to call when the key is pressed
---@param mods Modifier[]? The modifiers to use with the key (default to option)
local function global_shortcut(key, fn, mods)
  hs.hotkey.bind(mods or { "option" }, key, fn)
end

local kitty = require "kitty"

global_shortcut("n", kitty.hotkey_win)

local bob = require "bob"

global_shortcut("d", bob.selection_translate)
global_shortcut("s", bob.snip_translate)
global_shortcut("a", bob.input_translate)
global_shortcut("v", bob.pasteboard_translate)
global_shortcut("w", bob.show_window)
global_shortcut("s", bob.snip_ocr, { "option", "shift" })
