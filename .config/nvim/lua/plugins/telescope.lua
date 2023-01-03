local M = {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    config = function()
      require("telescope").load_extension "fzf"
    end,
  },
}

function M.config()
  local telescope = require "telescope"
  local actions = require "telescope.actions"
  telescope.setup {
    defaults = {
      mappings = {
        i = { -- TODO: open with window picker
          ["<esc>"] = actions.close, -- quit but esc
          ["<C-u>"] = false, -- clear promote
          ["<C-b>"] = actions.preview_scrolling_up,
          ["<C-f>"] = actions.preview_scrolling_down,
        },
      },
      file_ignore_patterns = { "node_modules", "vendor" },
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
    },
  }
end

return M
