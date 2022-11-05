local M = {}

local util = require('util')
local has_lspconfig, lspconfig = pcall(require, 'lspconfig')
local has_cmp_lsp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
if not has_lspconfig or not has_cmp_lsp then
  util.warn('lspconfig or cmp_nvim_lsp not found, skipping lsp config')
  M.setup = function() end
  return M
end

local make_capabilities = cmp_lsp.default_capabilities

local function keymap(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.noremap = opts.noremap or true
  opts.silent = opts.silent or true
  vim.keymap.set(mode, lhs, rhs, opts)
end

local on_attach_common = function(_, bufnr)
  local function buf_keymap(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.buffer = bufnr
    keymap(mode, lhs, rhs, opts)
  end

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_keymap('n', 'gd', [[<Cmd>Telescope lsp_definitions<CR>]],
    { desc = 'Go to definition' })
  buf_keymap('n', 'gD', [[<Cmd>Telescope lsp_type_definitions<CR>]],
    { desc = 'Go to type definitions' })
  buf_keymap('n', 'gr', [[<Cmd>Telescope lsp_references<CR>]],
    { desc = 'Go to references' })
  buf_keymap('n', 'gi', [[<Cmd>Telescope lsp_implementations<CR>]],
    { desc = 'Go to implementations' })
  buf_keymap('n', '<leader>sd', [[<Cmd>Telescope diagnostics bufnr=0<CR>]],
    { desc = 'Search all diagnostics if current buffer' })
  buf_keymap('n', '<leader>ss', [[<Cmd>Telescope lsp_document_symbols<CR>]],
    { desc = 'Search all symbols in current buffer' })
  buf_keymap('n', '<leader>k', vim.lsp.buf.hover, { buffer = bufnr, desc = 'Show hover' })
  buf_keymap('n', '<leader>K', vim.lsp.buf.signature_help,
    { buffer = bufnr, desc = 'Show signature help' })
  buf_keymap('n', '<leader>wa', function()
    vim.ui.input({
      prompt = 'Workspace folder to be added',
      default = vim.fn.expand('%:p:h'),
    }, function(dir)
      if dir then
        vim.lsp.buf.add_workspace_folder(dir)
      end
    end)
  end, { buffer = bufnr, desc = 'Add workspace folder' })
  buf_keymap('n', '<leader>wd', function()
    vim.ui.select(vim.lsp.buf.list_workspace_folders(), {
      prompt = 'Workspace folder to be removed'
    }, function(dir)
      if dir then
        vim.lsp.buf.remove_workspace_folder(dir)
      end
    end
    )
  end, { buffer = bufnr, desc = 'Remove workspace folder' })
  buf_keymap('n', '<leader>cn', function()
    return ':IncRename ' .. vim.fn.expand('<cword>')
  end, { expr = true, desc = 'Change variable name' })
  buf_keymap('n', '<leader>.', vim.lsp.buf.code_action, { desc = 'Show code action' })
  buf_keymap({ 'n', 'v' }, '<leader>f', function(opts)
    opts = opts or {}
    opts.async = true
    vim.lsp.buf.format(opts)
  end, { desc = 'Format code' })
end

local function process_config(config, reload)
  if type(config) == 'string' then
    if reload then
      return util.reload(config)
    else
      return require(config)
    end
  else -- table
    return config
  end
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

M.configs = {
  julials = 'lsp.julials',
  sumneko_lua = 'lsp.sumneko_lua',
}

M.setup = function()
  -- some simple servers, is not necessary to use a config file
  if vim.fn.executable('bash-language-server') == 1 then
    M.configs.bashls = { options = { filetypes = { 'bash', 'sh' } } }
  end

  if vim.fn.executable('taplo') == 1 then
    M.configs.taplo = {}
  end

  local lsp_reload = vim.api.nvim_create_augroup('LspReload', { clear = true })
  -- auto reload after this file
  util.create_source_autocmd {
    pattern = 'config/lsp.lua',
    callback = function()
      util.reload('config.lsp').setup()
    end,
    group = lsp_reload,
  }
  -- auto reload servers' config when config changes
  util.create_source_autocmd {
    pattern = 'lsp/*.lua',
    callback = function()
      local file = vim.fn.expand('<afile>')
      local server = vim.fs.basename(file):gsub('%.lua$', '')
      if server == 'init' then
        return
      end
      local config = process_config(M.configs[server], true)
      setup_server(server, config)
      print('Reloaded ' .. server)
    end,
    group = lsp_reload,
  }
  keymap('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
  keymap('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
  for server, config in pairs(M.configs) do
    setup_server(server, process_config(config))
  end
end

return M

-- vim:tw=76:ts=2:sw=2:et
