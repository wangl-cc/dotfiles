---@type LspConfig
local M = {}

if vim.env.__JULIA_LSP_DISABLE == "true" or vim.fn.executable "julia" == 0 then
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

M.options = {
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
