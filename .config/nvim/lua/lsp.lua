local lspconfig = require('lspconfig')
local telescope = require('telescope.builtin')
local Job = require 'plenary.job'

local M = {}

-- global mapping
local map = vim.keymap.set
local mapopts = { noremap = true, silent = true }
map('n', '<leader>e', vim.diagnostic.open_float, mapopts)
map('n', '[d', vim.diagnostic.goto_prev, mapopts)
map('n', ']d', vim.diagnostic.goto_next, mapopts)
map('n', '<leader>q', vim.diagnostic.setloclist, mapopts)

local on_attach_common = function(_, bufnr)
  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  map('n', '<leader>gd', telescope.lsp_definitions, bufopts)
  map('n', '<leader>gr', telescope.lsp_references, bufopts)
  map('n', '<leader>gi', telescope.lsp_implementations, bufopts)
  map('n', '<leader>gt', telescope.lsp_type_definitions, bufopts)
  map('n', '<leader>ld', function(opts)
    opts = opts or {}
    opts.bufnr = 0
    return telescope.diagnostics(opts)
  end, bufopts)
  map('n', '<leader>ls', telescope.lsp_document_symbols, bufopts)
  map('n', '<leader>k', vim.lsp.buf.hover, bufopts)
  map('n', '<leader>K', vim.lsp.buf.signature_help, bufopts)
  map('n', '<leader>wa', function()
    vim.ui.input({
      prompt = "Workspace folder to be added",
      default = vim.fn.expand('%:p:h'),
    }, function(dir)
      if dir then
        vim.lsp.buf.add_workspace_folder(dir)
      end
    end)
  end, bufopts)
  map('n', '<leader>wr', function()
    vim.ui.select(vim.lsp.buf.list_workspace_folders(), {
      prompt = 'Workspace folder to be removed'
    }, function(dir)
      if dir then
        vim.lsp.buf.remove_workspace_folder(dir)
      end
    end
    )
  end, bufopts)
  map('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
  map('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
  map({ 'n', 'v' }, '<leader>f', function(opts)
    opts = opts or {}
    opts.async = true
    vim.lsp.buf.format(opts)
  end, bufopts)
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
      vim.fn.expand('~/.config/julials/sys.dylib') or
      vim.fn.expand('~/.config/julials/sys.so') -- not works for windows
  local julia_cmd = {
    'julia', '--startup-file=no', '--history-file=no',
    '-e', [[pushfirst!(LOAD_PATH, "$(homedir())/.julia/environments/nvim_lsp")
      using LanguageServer
      popfirst!(LOAD_PATH)
      project_path = dirname(something(
        # current activated project, false to avoid search LOAD_PATH
        Base.active_project(false),
        # look Project.toml in the current working directory,
        # or parent directories, with $HOME as an upper boundary
        Base.current_project(),
        # current actived project, but search LOAD_PATH
        Base.active_project(),
        # use julia's default project
        ""
      ))
      depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
      symserver_store_path = joinpath(homedir(), ".config", "julials", "symbolstore")
      isdir(symserver_store_path) || mkpath(symserver_store_path)
      server = LanguageServer.LanguageServerInstance(
        stdin, stdout, project_path, depot_path, nothing, symserver_store_path, false
      )
      run(server)
    ]]
  }
  if vim.fn.filereadable(julia_img_user) == 1 then
    table.insert(julia_cmd, 4, '-J')
    table.insert(julia_cmd, 5, julia_img_user)
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
        '--project=~/.julia/environments/nvim_lsp',
        '-e', [[using Pkg; Pkg.add("LanguageServer")]]
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
end

if vim.fn.executable('bash-language-server') == 1 then
  lspconfig.bashls.setup {
    filetypes = { 'bash', 'sh' }
  }
end

return M

-- vim:tw=76:ts=2:sw=2:et
