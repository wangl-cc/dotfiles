-- shortcuts for the most common functions
local g = vim.g
local opt = vim.opt
local cmd = vim.cmd
local map = vim.keymap.set

local function silent_noremap(desc)
  return { noremap = true, silent = true, desc = desc }
end

-- leader key
g.mapleader = ' '
g.maplocalleader = ' '

-- Skip some remote provider loading
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0 -- even node is required for copilot but it use its own node

--- filetype detection
cmd 'filetype plugin indent on'

--- syntax highlight
cmd 'syntax on'

-- italic comments
cmd 'highlight Comment cterm=italic gui=italic'

-- use true colors
opt.termguicolors = true

-- show line number and relative line number
opt.number = true
opt.relativenumber = true

-- asking when quit
opt.confirm = true

-- when a bracket is inserted, briefly jump to the matching one
opt.showmatch = true

-- file encoding
opt.fileencoding = 'utf-8'

-- search
opt.hlsearch = true
opt.incsearch = true
opt.smartcase = true
map('n', '<leader>/', [[:nohlsearch<CR>:match<CR>]], silent_noremap 'nohlsearch and clear match')

-- split
opt.splitbelow = true
opt.splitright = true

-- Indent
opt.expandtab = true
opt.smarttab = true
opt.autoindent = true

-- spell
opt.spelloptions = 'camel,noplainbuffer'

-- folding
opt.foldexpr = 'nvim_treesitter#foldexpr()'
opt.foldnestmax = 3

-- highlight current line
opt.cursorline = true

-- keep 3 lines above and below the cursor
opt.scrolloff = 3

-- disable error bell
opt.errorbells = false

-- hide cmdline
opt.cmdheight = 0

-- check modeline
opt.modelines = 1

-- always show tab line
opt.showtabline = 2

-- always show a global status line, require nvim-0.7
opt.laststatus = 3

-- display sign in number column
opt.signcolumn = 'number'

-- gui cursor, only works when 'termguicolors' is on
-- The 'guicursor' don't use the highlight group by default,
-- this is a modified version of the default 'guicursor' with highlight group
-- more see: h 'guicursor'
opt.guicursor = 'n-v-c-sm:block-Cursor/lCursor,i-ci-ve:ver25-Cursor/lCursor,r-cr-o:hor20-Cursor/lCursor'

-- tex flavor
g.tex_flavor = 'latex'

-- commands
--- Remove all trailing blanks
map('n', '<leader>db', [[:%s/[ \\t]\\+$//<CR>]], silent_noremap 'Remove trailing blanks')

--- replace all matching words under cursor
--- <leader>cw/W
cmd [[
nnoremap <leader>cw : %s/\V\<<C-r><C-w>\>/<C-r><C-w>
nnoremap <leader>cW : %s/\V<C-r><C-a>/<C-r><C-a>
]]
