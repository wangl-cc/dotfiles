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
  local f = io.open(vim.fn.stdpath "config" .. "/lazy-lock.json", "r")
  if f then
    local lock = vim.json.decode(f:read "*a")
    vim.fn.system { "git", "-C", path, "checkout", lock["lazy.nvim"].commit }
  end
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
