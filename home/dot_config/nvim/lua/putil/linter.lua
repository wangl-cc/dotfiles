local M = {}

M.linters_by_ft = {}

M.linters_by_pattern = {}

---@alias Linter string

---@param ft string
---@param linters Linter|Linter[]
function M.registerf_for_ft(ft, linters)
  if type(linters) == "string" then
    linters = { linters }
  end
  M.linters_by_ft[ft] = linters
end

---@param pattern string
---@param linters Linter|Linter[]
function M.registerf_for_pattern(pattern, linters)
  if type(linters) == "string" then
    linters = { linters }
  end
  M.linters_by_pattern[pattern] = linters
end

---@param ft string
---@return Linter[]
function M.get_linters_by_ft(ft)
  return M.linters_by_ft[ft]
end

---@param file string
---@return Linter[]
function M.get_linters_by_pattern(file)
  local all_linters = {}
  for pattern, linters in pairs(M.linters_by_pattern) do
    if string.match(file, pattern) then
      vim.list_extend(all_linters, linters)
    end
  end
  return all_linters
end

return M
