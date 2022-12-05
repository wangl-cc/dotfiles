-- shortcuts for the most common functions
local g = vim.g
local o = vim.o
local opt = vim.opt
local cmd = vim.cmd

-- leader key
g.mapleader = " "
g.maplocalleader = " "

-- Skip some remote provider loading
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0 -- even node is required for copilot but it use its own node

--- filetype detection
cmd "filetype plugin indent on"

--- syntax highlight
cmd "syntax on"

-- italic comments
cmd "highlight Comment cterm=italic gui=italic"

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
o.fileencoding = "utf-8"

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
o.spelloptions = "camel,noplainbuffer"

-- folding
o.foldexpr = "nvim_treesitter#foldexpr()"
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
o.signcolumn = "number"

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

-- clipboard
opt.clipboard:append { "unnamedplus" }

-- tex flavor
g.tex_flavor = "latex"

-- disable builtin plugins
g.loaded_tutor_mode_plugin = 0
g.loaded_2html_plugin = 0
g.loaded_netrw = 0
g.loaded_netrwPlugin = 0
g.loaded_matchit = 0

-- set auto delete buffer for some filetypes
local auto_bd = vim.api.nvim_create_augroup("AutoDeleteBuffer", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "checkhealth" },
  callback = function()
    vim.bo.bufhidden = "delete"
  end,
  group = auto_bd,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitcommit", "gitrebase" },
  callback = function()
    vim.bo.bufhidden = "wipe"
  end,
  group = auto_bd,
})
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "lsp.log" },
  callback = function()
    vim.bo.bufhidden = "delete"
  end,
  group = auto_bd,
})

-- set tabstop and shiftwidth for some filetype
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "julia", "python" },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
  group = vim.api.nvim_create_augroup("IndentOptions", { clear = true }),
})

-- show cursor line only in active window
local cursorline = vim.api.nvim_create_augroup("CursorLine", { clear = true })
-- There is a win variable `cursorline` to store cursorline status when disable it
-- this should avoid to enable cursorline for some window
-- where the cursorline is disable, such as Telescope prompt
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  callback = function()
    local ok, cl = pcall(vim.api.nvim_win_get_var, 0, "cursorline")
    if ok and cl then
      vim.wo.cursorline = true
      vim.api.nvim_win_del_var(0, "cursorline")
    end
  end,
  group = cursorline,
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  callback = function()
    local cl = vim.wo.cursorline
    if cl then
      vim.api.nvim_win_set_var(0, "cursorline", cl)
      vim.wo.cursorline = false
    end
  end,
  group = cursorline,
})

-- treesitter for esh
local esh = vim.api.nvim_create_augroup("ESH", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "esh_*" },
  callback = function(args)
    local buffer = args.buf
    local ft = vim.bo[buffer].filetype:sub(5)
    local lang = ft == "gitconfig" and "git_config" or ft
    local scm = string.format([[
        (content) @%s @combined
        (code) @bash @combined
      ]], lang)
    vim.treesitter.query.set_query("embedded_template", "injections", scm)
    vim.treesitter.start(buffer, "embedded_template")
  end,
  group = esh
})

-- NOTE: use nvim inside nvim, there are some notes
-- 1. nvim --remote works but not well, nvr is much more recommended;
-- 2. this works in vim command line :!, only works in terminal inside nvim;
-- 3. environment variables must be set here instead of shell rc file;
if vim.fn.executable "nvr" == 1 then
  vim.env.VISUAL = "nvr"
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait"
else
  vim.env.VISUAL = "nvim --server " .. vim.v.servername .. " --remote"
end
