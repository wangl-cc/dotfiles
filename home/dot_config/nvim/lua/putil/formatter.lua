local install = require "putil.install"

local M = {}

M.options = {
  mason = false,
}

---@module "conform"

---@type table<string, string[]>
M.formatters_by_ft = {}

---@type string[]
M.formatters_tobe_installed = {}

---@type table<string, string>
local formatter_to_pkg = setmetatable({}, {
  -- If not specified, return the key itself, which means conform and mason have the same name
  __index = function(_, formatter) return formatter end,
})

---Register formatter(s) for given file type
---@param ft string File type
---@param formatter Pkg
function M.register(ft, formatter)
  formatter = install.parse(formatter, M.options)
  install.ensure_installed(formatter, M.formatters_tobe_installed, formatter_to_pkg)
  if not M.formatters_by_ft[ft] then M.formatters_by_ft[ft] = {} end
  table.insert(M.formatters_by_ft[ft], formatter.name)
end

---@return table<string, string[]>
function M.get_all_formatters() return M.formatters_by_ft end

---@param opts PkgOptions
function M.setup(opts) Util.tbl.merge_one(M.options, opts) end

function M.auto_install() install.auto_install(M.formatters_tobe_installed) end

return M
