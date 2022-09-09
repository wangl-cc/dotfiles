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

if vim.fn.executable('julia') == 1 then
  local julia_img_default = vim.fn.system(
    [[julia --startup-file=no --history-file=no -e "Base.JLOptions().image_file |> unsafe_string |> print"]]
  )
  local file_extension = julia_img_default:match([[sys(.*)]])
  local julia_img_user = vim.fn.expand('~/.config/julials/sys') .. file_extension
  local julia_cmd = {
    'julia', '--startup-file=no', '--history-file=no',
    '--sysimage', vim.fn.filereadable(julia_img_user) and julia_img_user or julia_img_default,
    '-e',
    [[
      pushfirst!(LOAD_PATH, "@nvim_lsp")
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
    properties = { "documentation", "detail", "additionalTextEdits" },
  }
  julia_capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown" }
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
          disabledDirs = { "test", "docs" },
        },
      },
    },
  }
end

return lspconfig

-- vim:tw=76:ts=2:sw=2:et
