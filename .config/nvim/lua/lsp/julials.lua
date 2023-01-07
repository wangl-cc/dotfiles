---@type LspConfig
local M = {}

if vim.env.__JULIA_LSP_DISABLE == "true" then
  M.disabled = true
  return M
end

M.setup_capabilities = function(capabilities)
  -- from wiki of LanguageServer.jl
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.preselectSupport = true
  capabilities.textDocument.completion.completionItem.tagSupport =
    { valueSet = { 1 } }
  capabilities.textDocument.completion.completionItem.deprecatedSupport = true
  capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
  capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
  capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = { "documentation", "detail", "additionalTextEdits" },
  }
  capabilities.textDocument.completion.completionItem.documentationFormat =
    { "markdown" }
  capabilities.textDocument.codeAction = {
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
  return capabilities
end

local os_name = vim.loop.os_uname().sysname
local julia_img_user = os_name == "Darwin"
    and vim.fn.expand "~/.config/julials/compiler/sys.dylib"
  or vim.fn.expand "~/.config/julials/sys.so"
local julia_cmd = {
  "julia",
  "--startup-file=no",
  "--history-file=no",
  vim.fn.expand "~/.config/julials/nvim_lsp/julials.jl",
}
if vim.fn.filereadable(julia_img_user) == 1 then
  table.insert(julia_cmd, "-J")
  table.insert(julia_cmd, julia_img_user)
end

function M.install()
  return require("plenary.job")
    :new({
      command = "julia",
      args = {
        "--startup-file=no",
        "--history-file=no",
        "--project=~/.config/julials/nvim_lsp",
        "-e",
        [[using Pkg; Pkg.instantiate()]],
      },
      on_exit = function(_, code)
        if code == 0 then
          print "julials installed."
        else
          print "julials installation failed."
        end
      end,
    })
    :start()
end

function M.compile()
  return require("plenary.job")
    :new({
      command = "julia",
      args = {
        "--history-file=no",
        "--project=~/.config/julials/nvim_lsp",
        vim.fn.expand "~/.config/julials/compiler/compile.jl",
      },
      on_exit = function(_, code)
        if code == 0 then
          print "julials compiled."
        else
          print "julials compilation failed."
        end
      end,
    })
    :start()
end

M.options = {
  cmd = julia_cmd,
  settings = {
    julia = {
      lint = {
        run = true,
        missingrefs = "none",
        disabledDirs = { "test", "docs" },
      },
    },
  },
}

return M
