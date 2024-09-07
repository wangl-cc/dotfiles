local tbl = require "util.table"

return {
  {
    "neovim/nvim-lspconfig",
    optional = true,
    opts = tbl.merge_options {
      servers = {
        ---@type LspConfig
        clangd = {
          options = {
            cmd = {
              "clangd",
              "--background-index",
              "--clang-tidy",
              "--header-insertion=iwyu",
              "--completion-style=detailed",
              "--function-arg-placeholders",
              "--fallback-style=llvm",
              "--offset-encoding=utf-16",
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
      -- we don't need to install treesitter for c, which is shipped with neovim
      ensure_installed = {
        "cpp",
      },
    },
  },
}
