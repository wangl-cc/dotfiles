--@type LspConfig
local M = {
  executable = "lua-language-server",
}

M.options = {
  cmd = { "lua-language-server" },
  settings = {
    Lua = {
      telemetry = { enable = false },
    },
  },
}

return M
