--@type LspConfig
local M = {
  executable = "lua-language-server",
}

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
