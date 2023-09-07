local M = {}

---@type table<string, table>
M.server_configurations = {}

function M.register(server, config) M.server_configurations[server] = config end

function M.setup()
  local lspconfig = require "lspconfig"
  for server, config in pairs(M.server_configurations) do
    lspconfig[server].setup(config)
  end
end

return M
