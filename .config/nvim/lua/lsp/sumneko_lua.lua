--@type LspConfig
local M = {}

if vim.fn.executable "lua-language-server" ~= 1 then
  M.disabled = true
  return M
end

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
