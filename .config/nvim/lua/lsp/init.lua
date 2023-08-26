local lspconfig = require "lspconfig"
local tbl = require "util.table"
local register = require "util.keymap"
local nu = require "util.nil"

local install = require "lsp.install"

local M = {}

---@param client lsp.Client
---@param buffer integer
---@param autofmt boolean|nil
local function on_attach_common(client, buffer, autofmt)
  -- Register default mappings
  register(require "lsp.keymap", { buffer = buffer, silent = true })

  -- Format
  -- If autofmt is nil, use global autofmt, otherwise use the value passed in
  autofmt = nu.or_default(autofmt, M.options.autofmt)
  require("lsp.format").setup(client, buffer, autofmt)

  -- Attach nvim-navic to LSP clients
  if client.supports_method "textDocument/documentSymbol" then
    local ok, navic = pcall(require, "nvim-navic")
    if ok then navic.attach(client, buffer) end
  end
end

---@class LspConfig
---@field disabled? boolean Whether to disable this lsp
---@field autofmt? boolean Whether to enable autofmt
---@field mason? boolean Whether to install lsp with mason
---@field setup_capabilities? fun(capabilities:table):table Setup capabilities
---@field options? table Options to be passed to lspconfig

---@param server string
---@param config LspConfig
local function setup_server(server, config)
  -- don't setup if server is disabled
  if config.disabled then return end
  local options = config.options or {}
  -- Ensure installation
  if nu.or_default(config.mason, true) then install.register(server) end
  -- Setup on_attach
  local on_attach
  if options.on_attach then
    on_attach = function(client, bufnr)
      on_attach_common(client, bufnr, config.autofmt)
      options.on_attach(client, bufnr)
    end
  else
    on_attach = function(client, bufnr)
      on_attach_common(client, bufnr, config.autofmt)
    end
  end
  -- Setup capabilities
  local capabilities = require("cmp_nvim_lsp").default_capabilities()
  if config.setup_capabilities then config.setup_capabilities(capabilities) end
  -- Setup server
  local new_options = vim.deepcopy(options)
  new_options.on_attach = on_attach
  new_options.capabilities = capabilities
  return lspconfig[server].setup(new_options)
end

---@class LspSetupOptions
---@field autofmt? boolean Whether to autofmt on save
---@field servers? table<string, LspConfig> List of servers to be setup

---@type LspSetupOptions
M.options = {
  autofmt = true,
  servers = {},
}

---@param opts LspSetupOptions
M.setup = function(opts)
  tbl.merge_one(M.options, opts)
  register({
    ["]"] = {
      callback = vim.diagnostic.goto_next,
      desc = "Go to next diagnostic",
    },
    ["["] = {
      callback = vim.diagnostic.goto_prev,
      desc = "Go to previous diagnostic",
    },
  }, { suffix = "d" })
  local icons = require("util.icons").diagnostic
  for name, icon in pairs(icons) do
    name = "DiagnosticSign" .. name:sub(1, 1):upper() .. name:sub(2)
    vim.fn.sign_define(name, { text = icon, texthl = name, numhl = name })
  end
  for server, config in pairs(M.options.servers) do
    setup_server(server, config)
  end

  install.ensure_installed()
end

return M

-- vim:tw=76:ts=2:sw=2:et
