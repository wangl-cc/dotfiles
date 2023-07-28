local tbl = require "util.table"

local M = {}

---@class notes.NotesOptions
---@field directory? string Directory to store notes for global mode
---@field extension? string Default file extension for notes
---@field open? Cmd | function():Cmd Open command or function that returns a command
---@field project_root_indicators? table<string, boolean> Indicators for project root
---@field find_project_root? string|string[]|fun(name: string, path: string):boolean
---@field telescope? table Options passed to telescope picker

---@type notes.NotesOptions
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
  project_root_indicators = {
    ".git",
    -- Lua
    ".stylua.toml",
    -- Julia
    "Project.toml",
    -- Python
    "pyproject.toml",
    "setup.py",
    "requirements.txt",
  },
  find_project_root = function(name, _)
    for _, indicator in ipairs(M.options.project_root_indicators) do
      if name == indicator then return true end
    end
    return false
  end,
  telescope = {},
}
---@param opts? notes.NotesOptions
M.setup = function(opts)
  opts = opts or {}
  opts.directory = opts.directory and vim.fs.normalize(opts.directory) or nil
  tbl.merge(M.options, opts)
  if not vim.loop.fs_stat(M.options.directory) then
    vim.fn.mkdir(M.options.directory, "p")
  end
end

return M
