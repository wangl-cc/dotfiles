local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local note = require "notes"

local display = function(entry)
  local options = note.options
  local extension = options.extension
  local hide_extension = options.hide_extension
  local name = entry:gsub("^" .. options.directory .. "/", "")
  local ext = vim.fn.fnamemodify(entry, ":e")
  if hide_extension and ext == extension then
    return vim.fn.fnamemodify(name, ":r")
  end
  return entry
end

local finder = function()
  return finders.new_table {
    results = note.get_note_list(),
    entry_maker = function(entry)
      local name = display(entry)
      return {
        value = entry,
        display = name,
        ordinal = name,
      }
    end,
  }
end

return require("telescope").register_extension {
  exports = {
    notes = function(opts)
      opts = opts or {}
      pickers
        .new(opts, {
          prompt_title = "Notes",
          finder = finder(),
          previewer = conf.file_previewer(opts),
          sorter = conf.generic_sorter(opts),
        })
        :find()
    end,
  },
}
