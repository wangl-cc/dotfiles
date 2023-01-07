---@type LspConfig
local M = {}

M.options = {
  cmd = { "lua-language-server" },
  settings = {
    Lua = {
      telemetry = { enable = false },
      workspace = { checkThirdParty = false },
    },
  },
}

return M
