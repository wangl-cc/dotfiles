local lsp_install = require "lsp.install"
local lsp_keymap = require "lsp.keymap"

local tbl = LDU.tbl

local nu = require "util.nil"

local M = {}

---@class LspGlobalOptions
M.options = {}

---@type table<string, table>
M.servers = {}

---@param client lsp.Client
---@param buffer integer
local function on_attach_common(client, buffer)
  -- Keymap
  lsp_keymap(buffer)

  -- Attach nvim-navic to LSP clients
  if client.supports_method "textDocument/documentSymbol" then
    local ok, navic = pcall(require, "nvim-navic")
    if ok then navic.attach(client, buffer) end
  end

  -- Attach lsp_signature to LSP clients
  local ok, signature = pcall(require, "lsp_signature")
  if ok then signature.on_attach(nil, buffer) end
end

---@class LspConfig
---@field disabled? boolean Whether to disable this lsp
---@field mason? boolean Whether to install lsp with mason
---@field options? table Options to be passed to lspconfig

---@param server string
---@param config LspConfig
function M.register(server, config)
  -- don't setup if server is disabled
  if config.disabled then return end

  -- Ensure installation
  if nu.or_default(config.mason, true) then lsp_install.register(server) end

  -- Setup Options
  local options = config.options and vim.deepcopy(config.options) or {}
  if options.on_attach then
    local on_attach_old = options.on_attach
    options.on_attach = function(client, bufnr)
      on_attach_common(client, bufnr)
      on_attach_old(client, bufnr)
    end
  else
    options.on_attach = on_attach_common
  end
  options.capabilities =
    require("cmp_nvim_lsp").default_capabilities(options.capabilities)

  -- Register
  M.servers[server] = options
end

function M.setup(opts)
  tbl.merge_one(M.options, opts)

  local lspconfig = require "lspconfig"
  lsp_install.setup()
  for server, options in pairs(M.servers) do
    lspconfig[server].setup(options)
  end
end

return M
