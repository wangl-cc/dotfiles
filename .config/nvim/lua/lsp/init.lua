local lspconfig = require('lspconfig')
local telescope = require('telescope.builtin')
local make_capabilities = require('cmp_nvim_lsp').default_capabilities
local map = vim.keymap.set
local util = require('util')

local M = {}

M.servers = {
  'bashls',
  'julials',
  'sumneko_lua',
}

local on_attach_common = function(_, bufnr)
  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  map('n', '<leader>gd', telescope.lsp_definitions, { desc = 'Go to definition' })
  map('n', '<leader>gr', telescope.lsp_references, { desc = 'Go to references' })
  map('n', '<leader>gi', telescope.lsp_implementations, { desc = 'Go to implementations' })
  map('n', '<leader>gt', telescope.lsp_type_definitions, { desc = 'Go to type definitions' })
  map('n', '<leader>ld', function(opts)
    opts = opts or {}
    opts.bufnr = 0
    return telescope.diagnostics(opts)
  end, { buffer = bufnr, desc = 'List all diagnostics if current buffer' })
  map('n', '<leader>ls', telescope.lsp_document_symbols,
    { buffer = bufnr, desc = 'List all symbols in current buffer' })
  map('n', '<leader>k', vim.lsp.buf.hover, { buffer = bufnr, desc = 'Show hover' })
  map('n', '<leader>K', vim.lsp.buf.signature_help,
    { buffer = bufnr, desc = 'Show signature help' })
  map('n', '<leader>aw', function()
    vim.ui.input({
      prompt = 'Workspace folder to be added',
      default = vim.fn.expand('%:p:h'),
    }, function(dir)
      if dir then
        vim.lsp.buf.add_workspace_folder(dir)
      end
    end)
  end, { buffer = bufnr, desc = 'Add workspace folder' })
  map('n', '<leader>dw', function()
    vim.ui.select(vim.lsp.buf.list_workspace_folders(), {
      prompt = 'Workspace folder to be removed'
    }, function(dir)
      if dir then
        vim.lsp.buf.remove_workspace_folder(dir)
      end
    end
    )
  end, { buffer = bufnr, desc = 'Remove workspace folder' })
  map('n', '<leader>cn', function()
    return ':IncRename ' .. vim.fn.expand('<cword>')
  end, { buffer = bufnr, expr = true, desc = 'Change variable name' })
  map('n', '<leader>.', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Show code action' })
  map({ 'n', 'v' }, '<leader>f', function(opts)
    opts = opts or {}
    opts.async = true
    vim.lsp.buf.format(opts)
  end, { buffer = bufnr, desc = 'Format code' })
end

local function setup_server(server, config)
  if not config then
    return
  end
  local options = config.options or {}
  local function on_attach(client, bufnr)
    on_attach_common(client, bufnr)
    if options.on_attach then
      options.on_attach(client, bufnr)
    end
  end

  local capabilities = make_capabilities()
  if config.setup_capabilities then
    config.setup_capabilities(capabilities)
  end
  local new_options = vim.deepcopy(options)
  new_options.on_attach = on_attach
  new_options.capabilities = capabilities
  return lspconfig[server].setup(new_options)
end

M.setup = function()
  local lsp_reload = vim.api.nvim_create_augroup('LspReload', { clear = true })
  map('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
  map('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
  for _, server in ipairs(M.servers) do
    local mod = 'lsp.' .. server
    local config = require(mod)
    setup_server(server, config)
    -- auto reload server config when it changes
    util.create_source_autocmd {
      pattern = 'lsp/' .. server .. '.lua',
      callback = function()
        config = util.reload(mod)
        setup_server(server, config)
      end,
      group = lsp_reload,
    }
  end
end

return M

-- vim:tw=76:ts=2:sw=2:et
