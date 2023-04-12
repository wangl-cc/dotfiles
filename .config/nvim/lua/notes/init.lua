local tbl = require "util.table"
local UI = require "notes.ui"

local M = {}

---@class Note
---@field bufnr number The buffer number
---@field ui? NuiPopup | NuiSplit The UI to show the note
---@field shown? boolean Whether the popup is shown

M.cache = {}

M.cached = false ---@type boolean Whether the notes have been cached

---@type table<string, Note> A table of notes
M.cache.note_tbl = {}

---@type string[] A list of note paths
M.cache.note_list = {}

---@param path string
---@return Note
local get_note = function(path)
  local note = M.cache.note_tbl[path]
  if not note then
    note = {}
    M.cache.note_tbl[path] = note
    table.insert(M.cache.note_list, path)
  end
  return note
end

---@param ntbl table<string, Note>
---@param nlist string[]
---@param dir string
local function find_notes(ntbl, nlist, dir)
  local stat = vim.loop.fs_stat(dir)
  if not stat or stat.type ~= "directory" then return end
  for path, type in vim.fs.dir(dir) do
    local full_path = dir .. "/" .. path
    if type == "file" then
      if not ntbl[full_path] then
        ntbl[full_path] = {}
        table.insert(nlist, full_path)
      end
    elseif type == "directory" then
      find_notes(ntbl, nlist, full_path)
    end
  end
end

---@param name string name of the note
---@return string path Full path to the note
M.normalize = function(name)
  local dir = M.options.directory
  local ext = M.options.extension
  if name:sub(-#ext - 1) ~= "." .. ext then name = name .. "." .. ext end
  return dir .. "/" .. name
end

M.cache_notes = function()
  find_notes(M.cache.note_tbl, M.cache.note_list, M.options.directory)
end

M.get_note_list = function()
  if not M.cached then
    M.cache_notes()
    M.cached = true
  end
  return M.cache.note_list
end

---@param name string file name of the note
---@return string title title of the note
local name2title = function(name)
  local title =
    name:gsub("_", " "):gsub("%.", " "):gsub("%-", " "):gsub("%a", string.upper, 1)
  return title
end

---@param name string Name of the note
---@return number | nil bufnr Buffer number of given path
local get_buffer = function(name)
  local path = M.normalize(name)
  local note = get_note(path)
  if note.bufnr and vim.api.nvim_buf_is_valid(note.bufnr) then return note.bufnr end
  local dir = M.options.directory
  if not vim.loop.fs_stat(path) then
    vim.fn.mkdir(dir, "p")
    vim.fn.writefile({ "# " .. name2title(name) }, path)
  end
  vim.cmd.badd(path)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr):match(path) then
      note.bufnr = bufnr
      vim.b[bufnr].note_name = name
      return bufnr
    end
  end
end

M.toggle = function(name)
  local bufnr = get_buffer(name)
  local path = M.normalize(name)
  if not bufnr then error("Could not get buffer for " .. path) end
  local note = get_note(path)
  local opts = vim.deepcopy(M.options.ui_opts)
  if opts.border then
    opts.border.text.top = opts.border.text.top or (" " .. name2title(name) .. " ")
  end
  note.shown, note.ui = UI.toggle(note.ui, bufnr, M.options.ui, note.shown, opts)
  return note
end

---@param name? string note name
M.toggle_note = function(name)
  if not name then name = vim.fn.input {
    prompt = "Note name: ",
  } end
  if not name or name == "" then return end
  M.toggle(name)
end

---@class NotesOptions
---@field directory string
---@field extension string
---@field hide_extension boolean
---@field ui notes.UIMethod
---@field ui_opts notes.NuiOptions

---@type NotesOptions
M.options = {
  directory = vim.fn.stdpath "state" .. "/notes", -- directory to store notes
  extension = "md", -- default file extension for notes
  hide_extension = true, -- hide file extension in picker
  -- ui = "split",
  ui = "popup",
  -- ui_opts = {
  --   size = "50",
  --   position = "right",
  --   enter = true,
  --   buf_options = {
  --     buflisted = false,
  --     filetype = "markdown",
  --   },
  -- },
  ui_opts = {
    relative = "editor",
    position = "50%",
    size = "80%",
    enter = true,
    border = {
      style = "rounded",
      text = {
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

---@param opts? NotesOptions
M.setup = function(opts)
  opts = opts or {}
  opts.directory = opts.directory and vim.fn.expand(opts.directory) or nil
  tbl.extend_inplace(M.options, opts)
end

return M
