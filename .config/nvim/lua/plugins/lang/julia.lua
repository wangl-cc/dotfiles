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
          ---@type lspconfig.options.julials
          options = {
            ---@diagnostic disable: missing-fields
            settings = {
              julia = {
                lint = {
                  run = true,
                  missingrefs = "all",
                  disabledDirs = { "test", "docs" },
                },
              },
            },
            ---@diagnostic enable: missing-fields
            ---@param client lsp.Client
            ---@param bufnr integer
            on_attach = function(client, bufnr)
              vim.api.nvim_buf_create_user_command(
                bufnr,
                "JuliaLSReIndex",
                function() client.rpc.notify "julia/refreshLanguageServer" end,
                {
                  nargs = 0,
                  desc = "Re-index Julia Language Server Cache",
                }
              )
            end,
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
  {
    "hkupty/iron.nvim",
    optional = true,
    opts = tbl.merge_options {
      config = {
        repl_definition = {
          julia = {
            command = { "julia", "--project", "-tauto" },
          },
        },
      },
    },
  },
}
