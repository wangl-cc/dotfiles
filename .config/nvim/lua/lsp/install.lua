local log = require "util.log"

local M = {}

M.server_list = {}

function M.register(server) table.insert(M.server_list, server) end

function M.ensure_installed()
  require("mason-lspconfig").setup {
    ensure_installed = M.server_list,
  }
end

return M
