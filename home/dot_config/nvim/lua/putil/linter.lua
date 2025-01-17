local M = {}

local install = require "putil.install"

---@type PkgOptions
M.options = {
  mason = false,
}

---@type table<string, string[]>
M.linters_by_ft = {}

---@type table<string, string[]>
M.linters_by_pattern = {}

---@type string[]
M.linters_tobe_installed = {}

---@type table<string, string>
local linter_to_pkg = setmetatable({}, {
  -- If not specified, return the key itself, which means conform and mason have the same name
  __index = function(_, linter) return linter end,
})

---@param ft string
---@param linter Pkg
function M.register_for_ft(ft, linter)
  linter = install.parse(linter, M.options)
  install.ensure_installed(linter, M.linters_tobe_installed, linter_to_pkg)
  if not M.linters_by_ft[ft] then M.linters_by_ft[ft] = {} end
  table.insert(M.linters_by_ft[ft], linter.name)
end

---@param pattern string
---@param linter Pkg
function M.register_for_pattern(pattern, linter)
  linter = install.parse(linter, M.options)
  install.ensure_installed(linter, M.linters_tobe_installed, linter_to_pkg)
  if not M.linters_by_pattern[pattern] then M.linters_by_pattern[pattern] = {} end
  table.insert(M.linters_by_pattern[pattern], linter.name)
end

---@param ft string
---@return string[]
function M.get_linters_by_ft(ft) return M.linters_by_ft[ft] end

---@param file string
---@return string[]
function M.get_linters_by_pattern(file)
  local all_linters = {}
  for pattern, linters in pairs(M.linters_by_pattern) do
    if string.match(file, pattern) then vim.list_extend(all_linters, linters) end
  end
  return all_linters
end

---@param options InstallOptions
function M.setup(options) Util.tbl.merge_one(M.options, options) end

function M.auto_install() install.auto_install(M.linters_tobe_installed) end

return M
