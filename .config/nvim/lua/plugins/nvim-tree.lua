local M = {
  opt = true,
  keys = [[<leader>tt]],
  cmd = 'NvimTreeToggle',
}

function M.config()
  require('nvim-tree').setup {
    sort_by = 'case_sensitive',
    renderer = {
      group_empty = true,
    },
    filters = {
      dotfiles = false,
      custom = {
        '^\\.git',
        '^\\.DS_Store',
        '^Icon\r',
      },
    },
    update_cwd = true,
  }
  vim.keymap.set({ 'n', 'v' }, '<leader>tt', '<Cmd>NvimTreeToggle<CR>',
    { silent = true, desc = 'Toggle the file explorer' })
end

return M
