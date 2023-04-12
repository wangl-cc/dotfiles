local tbl = require "util.table"

local M = {}

---@class Note
---@field name string The name of the note
---@field path string The path to the note
---@field winid? window THe window id of the note

M.cache = {}

M.cached = false ---@type boolean Whether the notes have been cached

---@type table<string, Note> A table of notes
M.cache.note_tbl = {}

---@type Note[] A list of notes
M.cache.note_list = {}

---@param ntbl table<string, Note>
---@param nlist string[]
---@param dir string
---@param prefix? string
local function find_notes(ntbl, nlist, dir, prefix)
  local stat = vim.loop.fs_stat(dir)
  if not stat or stat.type ~= "directory" then return end
  for path, type in vim.fs.dir(dir) do
    local name = prefix and prefix .. "/" .. path or path
    local full_path = dir .. "/" .. path
    if type == "file" then
      if not ntbl[name] then
        local note = { name = name, path = full_path }
        ntbl[name] = note
        table.insert(nlist, note)
      end
    elseif type == "directory" then
      find_notes(ntbl, nlist, full_path, name)
    end
  end
end

---@param name string name of the note
---@return string path Full path to the note
function M.note_path(name)
  local dir = M.options.directory
  local ext = M.options.extension
  if name:sub(-#ext - 1) ~= "." .. ext then name = name .. "." .. ext end
  return dir .. "/" .. name
end

function M.cache_notes()
  find_notes(M.cache.note_tbl, M.cache.note_list, M.options.directory)
end

function M.get_note_list()
  if not M.cached then
    M.cache_notes()
    M.cached = true
  end
  return M.cache.note_list
end

---@param name string
---@return Note
local function get_note(name)
  local ext = M.options.extension
  if name:sub(-#ext - 1) ~= "." .. ext then name = name .. "." .. ext end
  local note = M.cache.note_tbl[name]
  if not note then
    local path = M.note_path(name)
    note = { name = name, path = path } ---@type Note
    M.cache.note_tbl[name] = note
    table.insert(M.cache.note_list, note)
  end
  return note
end

---@param name string file name of the note
---@return string title title of the note
local function name2title(name)
  local ext = string.format(".%s$", M.options.extension)
  local title = name
    :gsub("_", " ")
    :gsub("%.", " ")
    :gsub("%-", " ")
    :gsub("%a", string.upper, 1)
    :gsub(ext, "")
  return title
end

---@param note Note
local function open_win(note)
  local open = M.options.open
  if type(open) == "function" then open = open() end
  vim.cmd(open .. " " .. note.path)
  local winid = vim.api.nvim_get_current_win()
  note.winid = winid
  vim.b.note_name = note.name
end

---@param note Note
local function open_note(note)
  if not vim.loop.fs_stat(note.path) then
    vim.fn.writefile({ "# " .. name2title(note.name) }, note.path)
  end
  open_win(note)
end

---@param name string Note name
function M.toggle(name)
  local note = get_note(name)
  if note.winid and vim.api.nvim_win_is_valid(note.winid) then
    local bufnr = vim.api.nvim_win_get_buf(note.winid)
    vim.bo[bufnr].buflisted = false
    vim.api.nvim_win_hide(note.winid)
    note.winid = nil
  else
    open_note(note)
  end
end

---@param name? string Note name
M.open = function(name)
  if not name then name = vim.fn.input {
    prompt = "Note name: ",
  } end
  if not name or name == "" then return end
  open_note(get_note(name))
end

---@class NotesOptions
---@field directory string
---@field extension string
---@field open Cmd | function():Cmd

---@type NotesOptions
M.options = {
  directory = vim.fn.stdpath "state" .. "/notes", -- directory to store notes
  extension = "md", -- default file extension for notes
  open = function()
    if vim.go.columns >= 180 then
      return "botright 80vsplit"
    else
      return "botright 20split"
    end
  end,
}

---@param opts? NotesOptions
M.setup = function(opts)
  opts = opts or {}
  opts.directory = opts.directory and vim.fn.expand(opts.directory) or nil
  tbl.extend_inplace(M.options, opts)
  if not vim.loop.fs_stat(M.options.directory) then
    vim.fn.mkdir(M.options.directory, "p")
  end
end

return M
