-- List functions
local M = {}

--- Append lists into the first one `base`.
---
--- This function only append the values in the lists, in the order of the lists.
--- If you want to merge the table part, use `merge` instead.
---
---@param base any[] List to be extended
---@param ... any[] Lists to be merged into base
---@return any[] # Extended list
function M.append(base, ...)
  Util.assert_type(base, "table")
  for i = 1, select("#", ...) do
    local other = select(i, ...)
    Util.assert_type(other, "table")
    for _, v in ipairs(other) do
      table.insert(base, v)
    end
  end
  return base
end

--- Truncate the list to the first `n` elements.
---
--- @param list any[] List to be truncated
--- @param n integer Number of elements to keep
function M.truncate(list, n)
  Util.assert_type(list, "table")
  Util.assert_type(n, "number")
  for i = n + 1, #list do
    list[i] = nil
  end
  return list
end

--- Remove all duplicate values from the list.
---
--- @param list any[] List to be made unique
function M.unique(list)
  Util.assert_type(list, "table")
  local seen = {}
  local j = 1
  for _, v in ipairs(list) do
    if not seen[v] then
      seen[v] = true
      list[j] = v
      j = j + 1
    end
  end
  M.truncate(list, j - 1)
  return list
end

return M
