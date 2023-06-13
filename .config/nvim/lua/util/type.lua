local M = {}

---@param value any Value to be checked
---@param expected string Expected type
M.assert = function(value, expected)
  assert(
    type(value) == expected,
    string.format("Expected type %s, got %s", expected, type(value))
  )
end

return M
