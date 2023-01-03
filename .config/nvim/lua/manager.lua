local util = require "util"

local path = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(path) then
  vim.fn.system {
    "git",
    "clone",
    "--filter",
    "blob:none",
    "https://github.com/folke/lazy.nvim.git",
    path,
  }
  -- use the stable tag
  vim.fn.system {
    "git",
    "-C",
    path,
    "checkout",
    "tags/stable",
  }
end
vim.opt.rtp:prepend(path)

local opts = {
  install = {
    colorscheme = { "tokyonight" },
  },
  ui = {
    border = "rounded",
  },
  defaults = {
    lazy = true,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "matchit",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "gzip",
        "zipPlugin",
      },
    },
  },
}

require("lazy").setup("plugins", opts)
