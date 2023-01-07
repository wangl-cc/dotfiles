local type_assert = require("util.misc").type_assert

-- Table operations
local M = {}

local can_merge = function(v)
  return type(v) == "table" and (vim.tbl_isempty(v) or not vim.tbl_islist(v))
end

---@param base table<any, any> Table to be extended
---@param other table<any, any> Table be merged into base
---@return table<any, any> Extended table
local function unsafe_deep_extend(base, other)
  for k, v in pairs(other) do
    if can_merge(v) and can_merge(base[k]) then
      unsafe_deep_extend(base[k], v)
    else
      base[k] = v
    end
  end
  return base
end

---@param base table<any, any> Table to be extended
---@param ... table<any, any> Tables to be merged into base
---@return table<any, any> Extended table
function M.extend_inplace(base, ...)
  type_assert(base, "table")
  for i = 1, select("#", ...) do
    local other = select(i, ...)
    type_assert(other, "table")
    unsafe_deep_extend(base, other)
  end
  return base
end

return M
