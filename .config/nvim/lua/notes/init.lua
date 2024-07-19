local cache = require "notes.cache"
local options = require("notes.config").options

---@module 'notes'

local M = {}

---@class notes.Note
---@field name string The name of the note
---@field path string The path to the note
---@field winid? window THe window id of the note

---@class notes.Scope
---@field scope `"global"` | `"project"` | `"buffer"` The scope of the note
---@field path? string The path to the project or buffer

---@param name string file name of the note
---@return string title title of the note
local function name2title(name)
  local title = name
    :gsub("%." .. options.extension, "")
    :gsub("_", " ")
    :gsub("%-", " ")
    :gsub("%a", string.upper, 1)
  return title
end

---@param note notes.Note
local function open_win(note)
  local open = options.open
  if type(open) == "function" then open = open() end
  vim.cmd(open .. " " .. note.path)
  local winid = vim.api.nvim_get_current_win()
  note.winid = winid
end

---@param note notes.Note
local function open_note(note)
  if not vim.uv.fs_stat(vim.fs.dirname(note.path)) then
    vim.fn.mkdir(vim.fs.dirname(note.path), "p")
  end
  if not vim.uv.fs_stat(note.path) then
    vim.fn.writefile({ "# " .. name2title(note.name) }, note.path)
  end
  open_win(note)
end

---@param scope notes.Scope
---@param name string notes.Note name
function M.toggle(scope, name)
  local note = cache.get_note(scope, name)
  if note.winid and vim.api.nvim_win_is_valid(note.winid) then
    local bufnr = vim.api.nvim_win_get_buf(note.winid)
    vim.bo[bufnr].buflisted = false
    vim.api.nvim_win_hide(note.winid)
    note.winid = nil
  else
    open_note(note)
  end
end

---@param scope notes.Scope
---@param name? string notes.Note name
function M.open(scope, name)
  if not name then name = vim.fn.input {
    prompt = "notes.Note name: ",
  } end
  if not name or name == "" then return end
  open_note(cache.get_note(scope, name))
end

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values

local finder = function(scope)
  return finders.new_table {
    results = cache.get_note_cache(scope).note_list,
    entry_maker = function(entry)
      local name = entry.name
      local path = entry.path
      return {
        value = path,
        display = name,
        ordinal = name,
      }
    end,
  }
end

M.find = function(scope)
  pickers
    .new(options.telescope, {
      prompt_title = "Notes",
      finder = finder(scope),
      previewer = conf.file_previewer(options),
      sorter = conf.generic_sorter(options),
    })
    :find()
end

M.setup = require("notes.config").setup

return M
