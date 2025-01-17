local M = {}

---@class PkgOptions
---@field mason boolean

---@class PkgSpec
---@field name string The name of the pkg to be install
---@field mason? boolean Whether to install the plugin using Mason

---@alias Pkg string|PkgSpec

---@param pkg Pkg
---@param options PkgOptions
---@return PkgSpec
function M.parse(pkg, options)
  if type(pkg) == "string" then
    return { name = pkg, mason = options.mason }
  else
    return {
      name = pkg.name,
      mason = Util.default(pkg.mason, options.mason),
    }
  end
end

---@param pkg PkgSpec
---@param list string[]
---@param pkg_to_mason table<string, string>
function M.ensure_installed(pkg, list, pkg_to_mason)
  if pkg.mason then table.insert(list, pkg_to_mason[pkg.name]) end
end

---@param pkgs string[]
function M.auto_install(pkgs)
  for _, pkg in ipairs(pkgs) do
    local registry = require "mason-registry"
    local ok, mason_pkg = pcall(registry.get_package, pkg)
    if ok then
      if not mason_pkg:is_installed() then
        mason_pkg:install():once(
          "closed",
          vim.schedule_wrap(function()
            if mason_pkg:is_installed() then
              vim.notify(
                pkg .. " has been installed successfully",
                vim.log.levels.INFO,
                { title = "Auto Install" }
              )
            else
              vim.notify(
                pkg
                  .. " failed to install, please check the logs by running :MasonLog",
                vim.log.levels.ERROR,
                { title = "Auto Install" }
              )
            end
          end)
        )
      end
    else
      vim.notify(
        pkg .. " is not available in the registry, please check the name",
        vim.log.levels.ERROR,
        { title = "Auto Install" }
      )
    end
  end
end

return M
