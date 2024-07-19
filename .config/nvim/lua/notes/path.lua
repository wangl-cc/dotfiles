local options = require("notes.config").options

local M = {}

local path_sep = vim.uv.os_uname().sysname == "Windows" and "\\" or "/"
local path_sep_len = #path_sep

--- Check if the directory has the correct path separator at the end, if not add it
---@param dir string path to directory
---@return string dir Path to directory with path separator at the end
local function check_dir(dir)
  if dir:sub(-path_sep_len) == path_sep then
    return dir
  else
    return dir .. path_sep
  end
end

local home_dir = check_dir(vim.fs.normalize "~")

--- Get the project root of given path
---@param path string path to find project root
---@return string # path to project root or nil if not found
function M.get_project_root(path)
  local found = vim.fs.find(options.find_project_root, {
    path = vim.fs.dirname(path),
    upward = true,
    stop = home_dir,
  })
  if found and #found > 0 then
    return check_dir(vim.fs.dirname(found[1]))
  else
    return home_dir
  end
end

--- Check if the name has the correct extension, if not add it
---@param name string name of the note
---@return string name Name with the correct extension
function M.check_extension(name)
  local ext = options.extension
  if name:sub(-#ext - 1) ~= "." .. ext then name = name .. "." .. ext end
  return name
end

---@param scope notes.Scope
---@return string dir Path to the notes directory
function M.note_dir(scope)
  if scope.scope == "global" then
    ---@diagnostic disable-next-line: param-type-mismatch
    return check_dir(scope.path or options.directory)
  elseif scope.scope == "project" then
    return check_dir(scope.path) .. ".notes/"
  elseif scope.scope == "buffer" then
    local project_root = M.get_project_root(scope.path)
    return check_dir(scope.path:gsub(project_root, project_root .. ".notes/"))
  else
    error("Invalid scope: " .. scope.scope)
  end
end

---@param scope notes.Scope
---@param name string name of the note
---@return string path Full path to the note
function M.note_path(scope, name) return M.note_dir(scope) .. M.check_extension(name) end

---@param ntbl notes.NoteTable
---@param nlist notes.NoteList
---@param dir string
---@param prefix? string
function M.find_notes(ntbl, nlist, dir, prefix)
  dir = check_dir(dir)
  prefix = prefix and check_dir(prefix)
  local stat = vim.uv.fs_stat(dir)
  if not stat or stat.type ~= "directory" then return end
  for path, type in vim.fs.dir(dir) do
    local name = prefix and prefix .. path or path
    local full_path = dir .. path
    if type == "file" then
      if not ntbl[name] then
        local note = { name = name, path = full_path }
        ntbl[full_path] = note
        table.insert(nlist, note)
      end
    elseif type == "directory" then
      M.find_notes(ntbl, nlist, full_path, name)
    end
  end
end

return M
