local lsp_keymap = require "putil.lsp.keymap"

local M = {}

---@class LspGlobalOptions
---@field mason? boolean Whether to install lsp with mason
---@field inlay_hint? boolean Whether enable inlay hint by default
M.options = {
  mason = false,
  inlay_hint = true,
}

---@type table<string, table>
M.servers = {}

---@type string[]
M.to_be_installed = {}

---@class LspConfig
---@field disabled? boolean Whether to disable this lsp
---@field mason? boolean Whether to install lsp with mason
---@field inlay_hints? boolean Whether to enable inlay hints
---@field options? table Options to be passed to lspconfig

---@param server string
---@param config? LspConfig
function M.register(server, config)
  config = config or {}
  -- don't setup if server is disabled
  if config.disabled then return end

  if Util.default(config.mason, M.options.mason) then
    table.insert(M.to_be_installed, server)
  end

  -- Process options
  local options = config.options or {}
  local on_attach_old = options.on_attach
  options.on_attach = function(client, bufnr)
    lsp_keymap(bufnr)

    if client:supports_method "textDocument/documentSymbol" then
      local ok, navic = pcall(require, "nvim-navic")
      if ok then navic.attach(client, bufnr) end
    end

    if
      Util.default(config.inlay_hints, M.options.inlay_hint)
      and client:supports_method "textDocument/inlayHint"
    then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end

    if on_attach_old then on_attach_old(client, bufnr) end
  end
  M.servers[server] = options
end

---@class LspSetupOptions
---@field options? LspGlobalOptions Global lsp options
---@field servers? table<string, LspConfig> List of servers to be setup

---@param opts? LspSetupOptions
function M.setup(opts)
  if opts then Util.tbl.merge_one(M.options, opts) end

  ---@diagnostic disable-next-line: missing-fields
  require("mason-lspconfig").setup {
    ensure_installed = M.to_be_installed,
  }

  local lspconfig = require "lspconfig"

  for server, options in pairs(M.servers) do
    lspconfig[server].setup(options)
  end
end

return M

-- vim:tw=76:ts=2:sw=2:et
