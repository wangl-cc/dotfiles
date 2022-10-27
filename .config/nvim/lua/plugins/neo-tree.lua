local M = {
  opt = true,
  branch = 'v2.x',
  keys = [[<leader>tt]],
  cmd = 'Neotree',
}

-- This is run this file is loaded
-- but not when this plugin is loaded
vim.g.neo_tree_remove_legacy_commands = 1

function M.config()
  require('neo-tree').setup {
    close_if_last_window = true,
    popup_border_style = 'rounded',
    sort_case_insensitive = true,
    use_popups_for_input = false,
    window = {
      position = 'left',
      width = 30,
      mappings = {
        ['<space>'] = 'noop',
        ['<cr>'] = 'open_with_window_picker',
        ['s'] = 'split_with_window_picker',
        ['S'] = 'noop',
        ['v'] = 'vsplit_with_window_picker',
      }
    },
  }
  vim.keymap.set({ 'n', 'v' }, '<leader>tt', '<Cmd>Neotree toggle<CR>',
    { silent = true, desc = 'Toggle the file explorer' })
end

return M
