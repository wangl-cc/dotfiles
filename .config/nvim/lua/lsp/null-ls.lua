---@alias NullLSBuiltinType "formatting" | "diagnostics" | "code_actions" | "completion" | "hover"
---@class NullLSBuiltinSpec
---@field type NullLSBuiltinType
---@field name string
---@field mason? boolean

local null_ls = require "null-ls"
local builtins = null_ls.builtins
local nu = require "util.nil"
local source_to_pkg = require("mason-null-ls.mappings.source").getPackageFromNullLs

local M = {}

---@class NullLSOptions
---@field sources? NullLSBuiltinSpec[]

---@param opts? NullLSOptions
function M.setup(opts)
  local sources = {}
  if opts and opts.sources then
    local ensure_install = {}
    for _, source in ipairs(opts.sources) do
      local builtin = builtins[source.type][source.name]
      if builtin then
        if nu.or_default(source.mason, true) then
          table.insert(ensure_install, source_to_pkg(source.name))
        end
        table.insert(sources, builtin)
      else
        require("util.log").warn(
          string.format(
            "Invalid null-ls builtin source: %s.%s",
            source.type,
            source.name
          ),
          "NullLS"
        )
      end
    end
    require("mason-null-ls").setup {
      ensure_installed = ensure_install,
      automatic_installation = false,
    }
  end
  null_ls.setup {
    border = "rounded",
    sources = sources,
  }
end

return M
