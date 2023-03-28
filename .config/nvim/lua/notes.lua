local tbl = require "util.table"

local M = {}

M.options = {
  directory = vim.fn.stdpath "state" .. "/notes", -- directory to store notes
  extension = "md", -- default file extension for notes
  hide_extension = true, -- hide file extension in picker
  open = "horizontal botright 20split", -- open command or function
}

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

local open = function(file)
  if type(M.options.open) == "function" then
    M.options.open(file)
  else
    vim.cmd(M.options.open .. " " .. file)
  end
end

M.open_note = function(name)
  local dir = M.options.directory
  if not name then name = vim.fn.input {
    prompt = "Note name: ",
  } end
  if not name or name == "" then return end
  local path = M.note_path(name)
  if not vim.loop.fs_stat(path) then
    vim.fn.mkdir(dir, "p")
    vim.fn.writefile({}, path)
  end
  open(path)
end

M.setup = function(opts)
  M.options = tbl.deep_extend("force", M.options, opts or {})
  M.options.directory = vim.fn.fnamemodify(M.options.directory, ":p")
end

return M
