local M = {}

---@module "conform"

---@type table<string, conform.FiletypeFormatter>
M.formatters_by_ft = {}

---Register formatter(s) for given file type
---@param ft string File type
---@param formatters conform.FiletypeFormatter
function M.register(ft, formatters)
  M.formatters_by_ft[ft] = formatters
end

---@return table<string, conform.FiletypeFormatter>
function M.get_all_formatters()
  return M.formatters_by_ft
end

return M
