local M = {}

M.plugins = {}

---@module 'lazy'

---@param plugin LazyPluginSpec
function M.register(plugin) table.insert(M.plugins, plugin) end

function M.get_plugins() return M.plugins end

return M
