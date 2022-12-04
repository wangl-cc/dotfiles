--@type LspConfig
local M = {
  executable = "lua-language-server",
}

M.options = {
  cmd = { "lua-language-server" },
  settings = {
    Lua = {
      telemetry = { enable = false },
    },
  },
  on_new_config = function(config, root_dir)
    if root_dir:match "nvim" then
      -- HACK: use neodev's on_new_config directly
      -- This seems to not works well, need to investigate
      require("neodev.config").setup {}
      require("neodev.lsp").on_new_config(config, root_dir)
    end
  end,
}

return M
