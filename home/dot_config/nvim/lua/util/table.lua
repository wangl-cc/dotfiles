-- Table operations
local M = {}

local should_merge = function(v) return type(v) == "table" end

--- Merge the second table `other` into the first one `base`.
---
--- For the table part, this function will merge the tables recursively.
--- If the same key exists in both tables, the value in the second table will be used.
--- The list part will be appended, not merged.
--- The `unsafe` means that this function will not check if the value is a table.
---
---@param base table<any, any> Table to be extended
---@param other table<any, any> Table be merged into base
---@return table<any, any> # Extended table
local function unsafe_merge(base, other)
  for k, v in pairs(other) do
    if type(k) == "number" then
      table.insert(base, v)
    elseif should_merge(v) and should_merge(base[k]) then
      unsafe_merge(base[k], v)
    else
      base[k] = v
    end
  end
  return base
end

--- Merge tables into the first one `base`.
---
--- If the same key exists in more than one table, the value in the last table will be used.
---
---@param base table<any, any> Table to be extended
---@param ... table<any, any> Tables to be merged into base
---@return table<any, any> # Extended table
function M.merge(base, ...)
  Util.assert_type(base, "table")
  for i = 1, select("#", ...) do
    local other = select(i, ...)
    if other then
      Util.assert_type(other, "table")
      unsafe_merge(base, other)
    end
  end
  return base
end

--- Merge table `other` into the `base`.
---
--- If the same key exists in more than one table, the value in the last table will be used.
---
---@param base table<any, any> Table to be extended
---@param other? table<any, any> Tables to be merged into base
---@return table<any, any> # Extended table
function M.merge_one(base, other)
  Util.assert_type(base, "table")
  if other then
    Util.assert_type(other, "table")
    unsafe_merge(base, other)
  end
  return base
end

--- Create a function to merge input options with default options.
---
--- The input options will be merged into the default options.
--- In table part, the input options will be merged recursively.
--- If the same key exists in both tables, the value in the input options will be used.
--- The list part will be appended, not merged.
--- @see merge
---@param opts table The default options
---@return fun(_, user_opts: table): table
M.merge_options = function(opts)
  return function(_, input_opts) return M.merge_one(opts, input_opts) end
end

return M
