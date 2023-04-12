local tbl = require "util.table"
local Popup = require "nui.popup"

local M = {}

local function get_notes(notes, dir)
  local stat = vim.loop.fs_stat(dir)
  if not stat or stat.type ~= "directory" then return notes end
  for path, type in vim.fs.dir(dir) do
    local full_path = dir .. "/" .. path
    if type == "file" then
      table.insert(notes, full_path)
    elseif type == "directory" then
      get_notes(notes, full_path)
    end
  end
  return notes
end

M.get_notes = function()
  local notes = {} -- cache notes?
  return get_notes(notes, M.options.directory)
end

M.note_path = function(file)
  local dir = M.options.directory
  local path = dir .. "/" .. file
  if file:sub(-#M.options.extension - 1) ~= "." .. M.options.extension then
    return path .. "." .. M.options.extension
  end
  return path
end

---@alias _NvimBorderStyle "'none'" | "'single'" | "'double'" | "'rounded'" | "'solid'" | "'shadow'"
---@alias Align "'left'" | "'center'" | "'right'"

---@class _NuiBorderOptions
---@field padding number | number[] | { top: number, left: number }
---@field style _NvimBorderStyle | table
---@field text { top: string | boolean, top_align?: Align, bottom: string | boolean, bottom_align?: Align }

---@alias _percentage string
---@alias _Size number | _percentage

---@class _NuiPopupOptions
---@field border? _NuiBorderOptions
---@field ns_id? number | string
---@field relative string | table
---@field position _Size | { row: _Size, col: _Size }
---@field size _Size | { width: _Size, height: _Size }
---@field enter? boolean
---@field focusable? boolean
---@field zindex? number
---@field buf_options? table
---@field win_options? table
---@field bufnr? number

---@param bufnr number
---@param opts? _NuiPopupOptions
local open_float = function(bufnr, opts)
  opts = vim.tbl_extend("force", M.options.popup_opts, opts or {})
  opts.bufnr = bufnr
  local popup = Popup(opts)
  popup:mount()
  return popup
end

---@param file string
---@param opts? _NuiPopupOptions
local open = function(file, opts)
  if M.options.open == "float" then
    vim.cmd.badd(file)
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(bufnr):match(file) then
        return open_float(bufnr, opts)
      end
    end
  else
    vim.cmd(M.options.open .. " " .. file)
  end
end

---@param name? string note name
---@param opts? _NuiPopupOptions
M.open_note = function(name, opts)
  local dir = M.options.directory
  if not name then name = vim.fn.input {
    prompt = "Note name: ",
  } end
  if not name or name == "" then return end
  local path = M.note_path(name)
  if not vim.loop.fs_stat(path) then
    vim.fn.mkdir(dir, "p")
    vim.fn.writefile({ "# " .. name:sub(1, 1):upper() .. name:sub(2, -1) }, path)
  end
  return open(path, opts)
end

M.options = {
  directory = vim.fn.stdpath "state" .. "/notes", -- directory to store notes
  extension = "md", -- default file extension for notes
  hide_extension = true, -- hide file extension in picker
  open = "float", -- how to open notes, "float" or valid vim command
  ---@type _NuiPopupOptions
  popup_opts = {
    relative = "editor",
    position = "50%",
    size = "80%",
    enter = true,
    border = {
      style = "rounded",
      text = {
        top = " Notes ",
        top_align = "center",
      },
    },
    buf_options = {
      buflisted = false,
      filetype = "markdown",
    },
    win_options = {
      number = true,
      relativenumber = true,
    },
  },
}

M.setup = function(opts)
  opts = opts or {}
  opts.directory = opts.directory and vim.fn.expand(opts.directory) or nil
  M.options = tbl.extend_inplace(M.options, opts)
end

return M
