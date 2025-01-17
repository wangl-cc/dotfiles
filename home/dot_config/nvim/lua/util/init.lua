local M = {}

---@param value any Value to be checked
---@param expected string Expected type
M.assert_type = function(value, expected)
  assert(
    type(value) == expected,
    string.format("Expected type %s, got %s", expected, type(value))
  )
end

-- Table functions
M.tbl = require "util.table"

-- List functions
M.list = require "util.list"

-- String functions
M.str = require "util.string"

-- Log functions
M.log = require "util.log"

-- A function to lazily load modules
M.import = require "util.import"

-- Common used icon characters
M.icons = require "util.icons"

-- A convenient function to register keymaps
M.register = require "util.keymap"

--- If the value is nil, return the default value, otherwise return the value.
---
---@generic T
---@param value any Value to be checked
---@default T Default value
---@return T
---
--- Unlike the `or` operator, if the value is `false`, it will still return the default value.
function M.default(value, default)
  if value == nil then
    return default
  else
    return value
  end
end

_G.Util = M
