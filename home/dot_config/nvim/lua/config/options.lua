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

-- show line number and relative line number
o.number = true
o.relativenumber = true

-- asking when quit
o.confirm = true

-- when a bracket is inserted, briefly jump to the matching one
o.showmatch = true

-- file format
o.fileencoding = "utf-8"
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
o.smarttab = true
o.autoindent = true
o.shiftround = true

-- spell
opt.spelloptions = { "camel", "noplainbuffer" }

-- folding
o.foldmethod = "expr"
o.foldexpr = "nvim_treesitter#foldexpr()"
o.foldnestmax = 3
o.foldlevelstart = 99

o.mousemoveevent = true

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

-- display sign with fixed width
o.signcolumn = "yes:1"

-- Auto write
o.autowrite = true

-- short message, details see :h 'shortmess'
o.shortmess = "aoOsWAIF"

-- preview incremental editing results
o.inccommand = "split"

-- gui cursor, only works when 'termguicolors' is on
-- The 'guicursor' don't use the highlight group by default,
-- this is a modified version of the default 'guicursor' with highlight group
-- more see: h 'guicursor'
opt.guicursor = {
  "n-v-c-sm:block-Cursor/lCursor",
  "i-ci-ve:ver25-Cursor/lCursor",
  "r-cr-o:hor20-Cursor/lCursor",
}

-- clipboard provider (for ssh session use OSC52)
if not vim.env.SSH_TTY then opt.clipboard:append { "unnamedplus" } end

-- Set WAKATIME_HOME here instead of shell rc file
-- because nvim may be not started from shell
vim.env.WAKATIME_HOME = vim.uv.os_homedir() .. "/.config/wakatime"

if vim.fn.executable "nvr" == 1 then vim.env.VISUAL = "nvr --remote-wait" end

--- Neovide options
if vim.g.neovide then
  g.neovide_input_macos_option_key_is_meta = "both"
  g.neovide_cursor_animation_length = 0.05

  g.neovide_theme = "auto"

  o.winblend = 30
  o.pumblend = 30

  -- vim.g.neovide_transparency = 0.9

  g.neovide_remember_window_size = true
  g.neovide_fullscreen = true

  vim.g.neovide_hide_mouse_when_typing = true

  g.neovide_cursor_vfx_mode = "railgun"
end
