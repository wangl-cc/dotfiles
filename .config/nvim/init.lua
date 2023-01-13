local auto_reload = require("util.reload").auto_reload

-- plugin unrelated configurations
auto_reload "config/options"
auto_reload "config/autocmds"

-- load plugins
require "config/manager"

-- Lazy load some configurations
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require "config/keymap"
  end,
  group = vim.api.nvim_create_augroup("LazyOtions", { clear = true }),
})

-- vim:tw=76:ts=2:sw=2:et
