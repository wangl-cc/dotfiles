-- shortcuts for the most common functions
local g = vim.g
local o = vim.o
local opt = vim.opt
local cmd = vim.cmd

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
o.termguicolors = true

-- show line number and relative line number
o.number = true
o.relativenumber = true

-- asking when quit
o.confirm = true

-- when a bracket is inserted, briefly jump to the matching one
o.showmatch = true

-- file encoding
o.fileencoding = 'utf-8'

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
o.spelloptions = 'camel,noplainbuffer'

-- folding
o.foldexpr = 'nvim_treesitter#foldexpr()'
o.foldnestmax = 3

-- highlight current line
o.cursorline = true

-- keep 3 lines above and below the cursor
o.scrolloff = 3

-- disable error bell
o.errorbells = false

-- NOTE: don't set cmdheight to 0 here
-- it will break the statusline in neovim 0.8.0
-- but it's ok for master branch
-- this options will be set by noice automatically
-- so don't set it here
-- o.cmdheight = 0

-- check modeline
o.modelines = 1

-- always show tab line
o.showtabline = 2

-- always show a global status line, require nvim-0.7
o.laststatus = 3

-- display sign in number column
o.signcolumn = 'number'

-- Auto write
o.autowrite = true

-- short message, details see :h 'shortmess'
o.shortmess = 'aoOsWAIFS'

-- gui cursor, only works when 'termguicolors' is on
-- The 'guicursor' don't use the highlight group by default,
-- this is a modified version of the default 'guicursor' with highlight group
-- more see: h 'guicursor'
opt.guicursor = {
  'n-v-c-sm:block-Cursor/lCursor',
  'i-ci-ve:ver25-Cursor/lCursor',
  'r-cr-o:hor20-Cursor/lCursor',
}

-- tex flavor
g.tex_flavor = 'latex'

-- disable builtin plugins
g.loaded_tutor_mode_plugin = 0
g.loaded_2html_plugin = 0

-- set auto delete buffer for some filetypes
local id = vim.api.nvim_create_augroup('AutoDeleteBuffer', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'checkhealth' },
  callback = function()
    vim.bo.bufhidden = 'delete'
  end,
  group = id
})
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = { 'lsp.log' },
  callback = function()
    vim.bo.bufhidden = 'delete'
  end,
  group = id
})

-- set tabstop and shiftwidth for some filetype
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'julia', 'python' },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
  group = vim.api.nvim_create_augroup('IndentOptions', { clear = true })
})
