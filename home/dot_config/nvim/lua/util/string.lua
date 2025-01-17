local M = {}

---@param s string
---@return string
M.capitalize = function(s) return s:sub(1, 1):upper() .. s:sub(2) end

return M
