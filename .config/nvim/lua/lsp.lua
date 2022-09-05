-- shortcuts for the most common functions
local map = vim.keymap.set
local opts = { noremap=true, silent=true }

-- mapping
map('n', '<leader>e', vim.diagnostic.open_float, opts)
map('n', '[d', vim.diagnostic.goto_prev, opts)
map('n', ']d', vim.diagnostic.goto_next, opts)
map('n', '<leader>q', vim.diagnostic.setloclist, opts)

local on_attach_common = function(_, bufnr)
  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  map('n', '<leader>gD', vim.lsp.buf.declaration, bufopts)
  map('n', '<leader>gd', vim.lsp.buf.definition, bufopts)
  map('n', '<leader>gr', vim.lsp.buf.references, bufopts)
  map('n', '<leader>gi', vim.lsp.buf.implementation, bufopts)
  map('n', '<leader>gt', vim.lsp.buf.type_definition, bufopts)
  map('n', '<leader>k', vim.lsp.buf.hover, bufopts)
  map('n', '<leader>K', vim.lsp.buf.signature_help, bufopts)
  map('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  map('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  map('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  map('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
  map('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
  map('n', '<leader>f', vim.lsp.buf.formatting, bufopts)
end

local lspconfig = require('lspconfig')

if vim.fn.executable('lua-language-server') == 1 then
  lspconfig.sumneko_lua.setup {
    cmd = { 'lua-language-server' },
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT',
          path = vim.split(package.path, ';'),
        },
        diagnostics = { globals = { 'vim' } },
        workspace = { library = vim.api.nvim_get_runtime_file('', true) },
        telemetry = { enable = false },
      },
    },
    on_attach = on_attach_common,
  }
end

-- TODO: add more lsp servers: julia
return lspconfig

-- vim:tw=76:ts=2:sw=2:et
