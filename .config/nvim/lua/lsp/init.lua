local M = {}

---@class LspSetupOptions
---@field options? LspGlobalOptions Global lsp options
---@field servers? table<string, LspConfig> List of servers to be setup

---@param opts LspSetupOptions
M.setup = function(opts)
  local options = opts.options or {}
  local servers = opts.servers or {}

  local lsp_config = require "lsp.config"
  for server, config in pairs(servers) do
    lsp_config.register(server, config)
  end

  lsp_config.setup(options)
end

return M

-- vim:tw=76:ts=2:sw=2:et
