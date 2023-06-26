local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    ---@type LspSetupOptions | fun(_, LspSetupOptions): LspSetupOptions
    opts = tbl.merge_options {
      servers = {
        julials = {
          disabled = vim.env.__JULIA_LSP_DISABLE == "true"
            or vim.fn.executable "julia" == 0,
          autoformat = false,
          setup_capabilities = function(capabilities)
            tbl.merge(capabilities.textDocument.completion.completionItem, {
              snippetSupport = true,
              preselectSupport = true,
              tagSupport = { valueSet = { 1 } },
              deprecatedSupport = true,
              insertReplaceSupport = true,
              labelDetailsSupport = true,
              commitCharactersSupport = true,
              resolveSupport = {
                properties = { "documentation", "detail", "additionalTextEdits" },
              },
              documentationFormat = { "markdown" },
            })
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
          end,
          ---@type lspconfig.options.julials
          options = {
            settings = {
              julia = {
                lint = {
                  run = true,
                  missingrefs = "none",
                  disabledDirs = { "test", "docs" },
                },
              },
            },
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = tbl.merge_options {
      ensure_installed = {
        "julia",
      },
    },
  },
}
