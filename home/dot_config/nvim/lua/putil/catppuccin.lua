local M = {}
---@module 'catppuccin'

---@class CtpIntegrations
M.integrations = {}

---@param integrations CtpIntegrations
function M.add_integrations(integrations)
  for k, v in pairs(integrations) do
    M.integrations[k] = v
  end
end

return M
