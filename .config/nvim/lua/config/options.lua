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

-- spell
opt.spelloptions = { "camel", "noplainbuffer" }

-- folding
o.foldexpr = "nvim_treesitter#foldexpr()"
o.foldnestmax = 3

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

local icons = require("util.icons").diagnostic
for name, icon in pairs(icons) do
  name = "DiagnosticSign" .. name:sub(1, 1):upper() .. name:sub(2)
  vim.fn.sign_define(name, { text = icon, texthl = name, numhl = name })
end

-- Set WAKATIME_HOME here instead of shell rc file
-- because nvim may be not started from shell
vim.env.WAKATIME_HOME = vim.loop.os_homedir() .. "/.config/wakatime"

if vim.fn.executable "nvr" == 1 then
  vim.env.VISUAL = "nvr -O"
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait"
end

-- File specific options

---@alias IndentStyle "tab" | "space"

---@type table<string, IndentStyle>
local indent_style_by_ft = {
  gitconfig = "tab",
  make = "tab",
}

---@type table<string, number>
local indent_size_by_ft = {
  python = 4,
  julia = 4,
  rust = 4,
  fish = 4,
}

---@type table<string, number>
local tab_width_by_ft = {}

---@type table<string, number>
local max_line_length_by_ft = {
  julia = 92,
  rust = 100,
  latex = 0,
  typst = 0,
  markdown = 0,
}
local default_max_line_length = 76

local default_indent_style = "space"
local default_indent_size = 2

local group = vim.api.nvim_create_augroup("options", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local bufnr = args.buf
    local bo = vim.bo[bufnr]

    if bo.buftype ~= "" then return end

    local ft = bo.filetype

    -- Respect the `editorconfig` settings
    local editorconfig = vim.b[bufnr].editorconfig
    if not editorconfig or type(editorconfig) ~= "table" then editorconfig = {} end
    local indent_style = editorconfig.indent_style
      or indent_style_by_ft[ft]
      or default_indent_style
    local indent_size = tonumber(editorconfig.indent_size) or indent_size_by_ft[ft]
    local tab_width = tonumber(editorconfig.tab_width) or tab_width_by_ft[ft]
    local max_line_length = editorconfig.max_line_length or max_line_length_by_ft[ft]

    if indent_style == "space" then
      bo.expandtab = true
    elseif indent_style == "tab" then
      bo.expandtab = false
    else
      require("util.log").warn(
        "Unknown indent style " .. indent_style .. ", fallback to 'space'",
        "options"
      )
      bo.expandtab = true
    end

    if indent_size then
      bo.shiftwidth = indent_size
      bo.softtabstop = -1
    else
      if indent_style == "space" then
        bo.shiftwidth = default_indent_size
        bo.softtabstop = -1
      else
        bo.shiftwidth = 0
        bo.softtabstop = 0
      end
    end

    if tab_width then
      bo.tabstop = tab_width
    else
      if indent_size then
        bo.tabstop = indent_size
      elseif indent_style == "space" then
        bo.tabstop = default_indent_size
      end
    end

    if max_line_length then
      local n = tonumber(max_line_length)
      if n then
        bo.textwidth = n
      elseif max_line_length == "off" then
        bo.textwidth = 0
      else
        require("util.log").warn(
          "Invalid max line length "
            .. max_line_length
            .. ", fallback to "
            .. default_max_line_length,
          "options"
        )
        bo.textwidth = default_max_line_length
      end
    else
      bo.textwidth = default_max_line_length
    end
  end,
  group = group,
})
