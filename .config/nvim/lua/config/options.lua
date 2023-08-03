-- shortcuts for the most common functions
local g = vim.g
local o = vim.o
local opt = vim.opt

-- leader key
g.mapleader = " "
g.maplocalleader = " "

-- Skip some remote provider loading
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0 -- even node is required for copilot but it use its own node

-- use true colors
o.termguicolors = true
o.pumblend = 10

-- show line number and relative line number
o.number = true
o.relativenumber = true

-- asking when quit
o.confirm = true

-- when a bracket is inserted, briefly jump to the matching one
o.showmatch = true

-- file encoding
o.fileencoding = "utf-8"

-- file format
o.expandtab = true
o.shiftwidth = 2
o.softtabstop = 2
o.tabstop = 8
-- 80 is the standard terminal width
-- but the number and sign column takes 5 columns
-- so the textwidth is 74 to make sure the text is not wrapped
o.textwidth = 74
o.fileformat = "unix"
o.fixendofline = true

-- search
o.hlsearch = true
o.incsearch = true
o.smartcase = true

-- split
o.splitbelow = true
o.splitright = true

-- Indent
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.smarttab = true
o.autoindent = true

-- spell
opt.spelloptions = { "camel", "noplainbuffer" }

-- folding
o.foldexpr = "nvim_treesitter#foldexpr()"
o.foldnestmax = 3

-- highlight current line
o.cursorline = true

-- keep 3 lines above and below the cursor
o.scrolloff = 3

-- disable error bell
o.errorbells = false

-- always show tab line
o.showtabline = 2

-- always show a global status line, require nvim-0.7
o.laststatus = 3

-- display sign in number column
o.signcolumn = "yes:1"

-- Auto write
o.autowrite = true

-- short message, details see :h 'shortmess'
o.shortmess = "aoOsWAIF"

-- gui cursor, only works when 'termguicolors' is on
-- The 'guicursor' don't use the highlight group by default,
-- this is a modified version of the default 'guicursor' with highlight group
-- more see: h 'guicursor'
opt.guicursor = {
  "n-v-c-sm:block-Cursor/lCursor",
  "i-ci-ve:ver25-Cursor/lCursor",
  "r-cr-o:hor20-Cursor/lCursor",
}

-- gui font, only works for GUI version like `neovide`
o.guifont = "JetBrainsMono Nerd Font:h13"

if g.goneovim == 1 then
  o.cmdheight = 0 -- goneovim has its own cmdline
  o.scrolloff = 0 -- This is not works well in goneovim
end

-- clipboard
opt.clipboard:append { "unnamedplus" }

-- tex flavor
g.tex_flavor = "latex"

-- Set WAKATIME_HOME here instead of shell rc file
-- because nvim may be not started from shell
vim.env.WAKATIME_HOME = vim.loop.os_homedir() .. "/.config/wakatime"

-- NOTE: use nvim inside nvim, there are some notes
-- 1. nvim --remote works but not well, nvr is much more recommended;
-- 2. this doesn't work in vim command line :!, only works in terminal inside nvim;
-- 3. environment variables must be set here instead of shell rc file;
if vim.fn.executable "nvr" == 1 then
  vim.env.VISUAL = "nvr"
  vim.env.JULIA_EDITOR = "nvr -O"
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait"
else
  ---@diagnostic disable-next-line: undefined-field
  vim.env.VISUAL = "nvim --server " .. vim.v.servername .. " --remote"
end
