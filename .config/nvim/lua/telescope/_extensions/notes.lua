local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local note = require "notes"

local finder = function()
  return finders.new_table {
    results = note.get_note_list(),
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
