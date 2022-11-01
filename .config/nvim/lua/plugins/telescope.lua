local M = {
  opt = true,
  cmd = 'Telescope',
  keys = { '<leader>l', 'gd', 'gD', 'gr', 'gi' },
  module = 'telescope',
  wants = { 'telescope-fzf-native.nvim', 'plenary.nvim' },
  requires = { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
}

function M.config()
  local telescope = require('telescope')
  local actions = require('telescope.actions')
  telescope.setup {
    defaults = {
      mappings = {
        i = { -- TODO: open with window picker
          ['<esc>'] = actions.close, -- quit but esc
          ['<C-u>'] = false, -- clear promote
          ['<C-b>'] = actions.preview_scrolling_up,
          ['<C-f>'] = actions.preview_scrolling_down,
        },
      },
      file_ignore_patterns = { 'node_modules', 'vendor' },
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = 'smart_case',
      }
    }
  }
  telescope.load_extension('fzf')
end

return M
