local M = {
  requires = { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
}

function M.config()
  local actions = require('telescope.actions')
  local builtins = require('telescope.builtin')
  local map = vim.keymap.set
  require('telescope').setup {
    defaults = {
      mappings = {
        i = {
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
  map('n', '<leader>lf', builtins.find_files, { desc = 'List files in CWD' })
  map('n', '<leader>lk', builtins.keymaps, { desc = 'List keymaps' })
  map('n', '<leader>lb', builtins.buffers, { desc = 'List buffers' })
  map('n', '<leader>lh', builtins.help_tags, { desc = 'List help tags' })
  map('n', '<leader>lw', builtins.live_grep, { desc = 'Live grep' })
  map('n', '<leader>lgc', builtins.git_commits, { desc = 'Show git log' })
  map('n', '<leader>lgb', builtins.git_bcommits, { desc = 'Show git log of current file' })
  map('n', '<leader>lgs', builtins.git_status, { desc = 'Show git status' })
end

return M
