local note_path = require "notes.path"

local M = {}

---@alias notes.NoteTable table<string, notes.Note>
---@alias notes.NoteList notes.Note[]

---@class notes.NoteCache
---@field cached? boolean Whether the notes have been cached
---@field note_tbl notes.NoteTable A table of notes
---@field note_list notes.NoteList A list of notes

---@class notes.NoteCaches
---@field global notes.NoteCache
---@field project table<string, notes.NoteCache>
---@field buffer table<number, notes.NoteCache>

---@type notes.NoteCaches
local caches = {
  global = {
    note_tbl = {},
    note_list = {},
  },
  project = {},
  buffer = {},
}
setmetatable(caches, {
  ---@param t notes.NoteCaches
  ---@param k notes.Scope
  ---@return notes.NoteCache
  __index = function(t, k)
    if k.scope == "global" then return rawget(t, k.scope) end
    local scope_caches = rawget(t, k.scope)
    local cache = scope_caches[k.path]
    if not cache then
      cache = {
        note_tbl = {},
        note_list = {},
      }
      scope_caches[k.path] = cache
    end
    return cache
  end,
})

---@param scope notes.Scope
---@return notes.NoteCache
function M.get_note_cache(scope)
  ---@type notes.NoteCache
  local cache = caches[scope]
  if not cache.cached then
    cache.note_tbl = {}
    cache.note_list = {}
    note_path.find_notes(cache.note_tbl, cache.note_list, note_path.note_dir(scope))
    cache.cached = true
  end
  return cache
end

---@param scope notes.Scope
---@param name string
---@return notes.Note
function M.get_note(scope, name)
  name = note_path.check_extension(name)
  local cache = M.get_note_cache(scope)
  local path = vim.fs.normalize(note_path.note_path(scope, name))
  local note = cache.note_tbl[path]
  if not note then
    note = { name = name, path = path } ---@type notes.Note
    table.insert(cache.note_list, note)
    cache.note_tbl[path] = note
  end
  return note
end

return M
