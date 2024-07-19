local path = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(path) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    path,
  }
end
vim.opt.rtp:prepend(path)

---@type LazyConfig
local opts = {
  dev = {
    path = "~/Repos/NeoVim",
    patterns = { "wangl-cc" },
    fallback = true,
  },
  install = {
    colorscheme = { "catppuccin" },
  },
  ui = {
    border = "rounded",
  },
  defaults = {
    lazy = true,
  },
  checker = {
    check_pinned = true,
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

require("lazy").setup({
  { import = "plugins" },
  { import = "plugins.lang" },
}, opts)
