-- shortcuts for the most common functions
local g = vim.g
local opt = vim.opt
local cmd = vim.cmd
local map = vim.keymap.set

local silent_noremap = { noremap = true, silent = true }

-- leader key
g.mapleader = ','
g.maplocalleader = ';'

-- Skip some remote provider loading
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0

--- filetype detection
cmd 'filetype plugin indent on'

--- syntax highlight
cmd 'syntax on'

-- italic comments
cmd 'highlight Comment cterm=italic gui=italic'

-- use ture colors
opt.termguicolors = true

-- show line number and relative line number
opt.number = true
opt.relativenumber = true

-- asking when quit
opt.confirm = true

-- when a bracket is inserted, briefly jump to the matching one
opt.showmatch = true

-- show command in bottom of screen
opt.showcmd = true

-- file encoding
opt.fileencoding = 'utf-8'

-- search
opt.hlsearch = true
opt.incsearch = true
opt.smartcase = true
--- clear search regiser and match with <leader>/
map('n', '<leader>/', [[:let @/=''<CR>:match<CR>]], silent_noremap)

-- split
opt.splitbelow = true
opt.splitright = true

-- Indent
opt.expandtab = true
opt.smarttab = true
opt.autoindent = true

-- folding
opt.foldexpr = 'nvim_treesitter#foldexpr()'
opt.foldnestmax = 3

-- highlight current line
opt.cursorline = true

-- keep 3 lines above and below the cursor
opt.scrolloff = 3

-- disable error bell
opt.errorbells = false

-- check modeline
opt.modelines = 1

-- always show tab line
opt.showtabline = 2

-- always show a global status line, requir nvim-0.7
opt.laststatus = 3

-- display sign in number column
opt.signcolumn = 'number'

-- gui cursor, only works when termguicolors is on
-- The guicursor don't use the highlight group by default,
-- this is a modified version of the default guicursor with highlight group
-- more see: h 'guicursor'
opt.guicursor = 'n-v-c-sm:block-Cursor/lCursor,i-ci-ve:ver25-Cursor/lCursor,r-cr-o:hor20-Cursor/lCursor'

-- tex flavor
g.tex_flavor = 'latex'

-- commands
--- Remove all tariling blanks
map('n', '<leader>db', [[:%s/[ \\t]\\+$//<CR>]], silent_noremap)

-- hightlight and replace <cword>(w) or <cWORD>(W)
--- highlight all matching words under cursor
--- <leader>hw/W
map('n', '<leader>hw',
  [[:exec 'match Search /\V\<' . expand('<cword>') . '\>/'<CR>]],
  silent_noremap)
map('n', '<leader>hW',
  [[:exec 'match Search /\V' . expand('<cWORD>') . '/'<CR>]],
  silent_noremap)
--- replace all matching words under cursor
--- [count]<leader>cw/W
--- if [count] is not given, replace all matching
--- if [count] is given, replace matchings in [count] lines
local function create_replace(pattern, count)
  return function(nword)
    if nword and #nword > 0 then
      if not count or count == 0 then
        cmd([[%s/\V]] .. pattern .. [[/]] .. nword .. [[/g]])
      else
        cmd([[s/\V]] .. pattern .. [[/]] .. nword .. [[/g ]] .. count)
      end
      cmd [[let @/ = '']]
    end
  end
end

map('n', '<leader>cw', function()
  local cword = vim.fn.expand('<cword>')
  local pattern = [[\<]] .. cword .. [[\>]]
  local replace = create_replace(pattern, vim.v.count)
  vim.ui.input({ prompt = 'New word: ', default = cword }, replace)
end, silent_noremap)
map('n', '<leader>cW', function()
  local cword = vim.fn.expand('<cWORD>')
  local replace = create_replace(cword, vim.v.count)
  vim.ui.input({ prompt = 'New word: ', default = cword }, replace)
end, silent_noremap)
