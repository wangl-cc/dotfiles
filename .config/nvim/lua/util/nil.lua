-- Desc: nil util functions
local M = {}

--- Return the value if it is not nil, otherwise return the default value.
---
---@generic T
---@param value T|nil
---@param default T
---@return T
function M.or_default(value, default)
  if value == nil then return default end
  return value
end

return M
