local lspconfig = require('lspconfig')
local telescope = require('telescope.builtin')
local Job = require 'plenary.job'

local M = {}

-- global mapping
local map = vim.keymap.set
map('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
map('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })

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
  map('n', '<leader>wa', function()
    vim.ui.input({
      prompt = 'Workspace folder to be added',
      default = vim.fn.expand('%:p:h'),
    }, function(dir)
      if dir then
        vim.lsp.buf.add_workspace_folder(dir)
      end
    end)
  end, { buffer = bufnr, desc = 'Add workspace folder' })
  map('n', '<leader>wr', function()
    vim.ui.select(vim.lsp.buf.list_workspace_folders(), {
      prompt = 'Workspace folder to be removed'
    }, function(dir)
      if dir then
        vim.lsp.buf.remove_workspace_folder(dir)
      end
    end
    )
  end, { buffer = bufnr, desc = 'Remove workspace folder' })
  map('n', '<leader>rn', vim.lsp.buf.rename, { buffer = bufnr, desc = 'Rename variable' })
  map('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Show code action' })
  map({ 'n', 'v' }, '<leader>f', function(opts)
    opts = opts or {}
    opts.async = true
    vim.lsp.buf.format(opts)
  end, { buffer = bufnr, desc = 'Format code' })
end

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

if vim.fn.executable('julia') == 1 and vim.env.__JULIA_LSP_DISABLE ~= 'true' then
  local os_name = vim.loop.os_uname().sysname
  local julia_img_user = os_name == 'Darwin' and
      vim.fn.expand('~/.config/julials/compiler/sys.dylib') or
      vim.fn.expand('~/.config/julials/sys.so') -- not works for windows
  local julia_cmd = {
    'julia', '--startup-file=no', '--history-file=no',
    vim.fn.expand('~/.config/julials/nvim_lsp/julials.jl'),
  }
  if vim.fn.filereadable(julia_img_user) == 1 then
    table.insert(julia_cmd, '-J')
    table.insert(julia_cmd, julia_img_user)
  end
  -- from wiki of LanguageServer.jl
  local julia_capabilities = vim.lsp.protocol.make_client_capabilities()
  julia_capabilities.textDocument.completion.completionItem.snippetSupport = true
  julia_capabilities.textDocument.completion.completionItem.preselectSupport = true
  julia_capabilities.textDocument.completion.completionItem.tagSupport = { valueSet = { 1 } }
  julia_capabilities.textDocument.completion.completionItem.deprecatedSupport = true
  julia_capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
  julia_capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
  julia_capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
  julia_capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = { 'documentation', 'detail', 'additionalTextEdits' },
  }
  julia_capabilities.textDocument.completion.completionItem.documentationFormat = { 'markdown' }
  julia_capabilities.textDocument.codeAction = {
    dynamicRegistration = true,
    codeActionLiteralSupport = {
      codeActionKind = {
        valueSet = (function()
          local res = vim.tbl_values(vim.lsp.protocol.CodeActionKind)
          table.sort(res)
          return res
        end)(),
      },
    },
  }

  lspconfig.julials.setup {
    cmd = julia_cmd,
    on_attach = on_attach_common,
    capabilities = julia_capabilities,
    settings = {
      julia = {
        lint = {
          run = true,
          disabledDirs = { 'test', 'docs' },
        },
      },
    },
  }

  function M.install_julials()
    return Job:new {
      command = 'julia',
      args = {
        '--startup-file=no', '--history-file=no',
        '--project=~/.config/julials/nvim_lsp',
        '-e', [[using Pkg; Pkg.insantiate()]]
      },
      on_exit = function(_, code)
        if code == 0 then
          print('julials installed.')
        else
          print('julials installation failed.')
        end
      end,
    }:start()
  end

  function M.compile_julials()
    return Job:new {
      command = 'julia',
      args = {
        '--history-file=no',
        '--project=~/.config/julials/nvim_lsp',
        vim.fn.expand('~/.config/julials/compiler/compile.jl'),
      },
      on_exit = function(_, code)
        if code == 0 then
          print('julials compiled.')
        else
          print('julials compilation failed.')
        end
      end,
    }:start()
  end
end

if vim.fn.executable('bash-language-server') == 1 then
  lspconfig.bashls.setup {
    filetypes = { 'bash', 'sh' }
  }
end

return M

-- vim:tw=76:ts=2:sw=2:et
