local M = {
  opt = true,
  keys = {
    '<leader>tr',
    '<leader>sc',
    '<leader>sl',
    '<leader>sf',
    '<leader>sm',
    '<leader>mc',
    '<leader>md',
  },
}
function M.config()
  local iron = require('iron.core')
  iron.setup {
    config = {
      repl_open_cmd = function(bufnr)
        -- HACK: set the filetype to 'iron' to detect it when needed
        vim.api.nvim_buf_set_option(bufnr, 'filetype', 'iron')
        return require('iron.view').split.vertical.botright(80, {
          number = false,
          relativenumber = false,
        })(bufnr)
      end,
      repl_definition = {
        julia = {
          command = { 'julia', '--project' }
        }
      },
    },
    keymaps = {
      send_motion = '<leader>sc',
      visual_send = '<leader>sc',
      send_file = '<leader>sf',
      send_line = '<leader>sl',
      send_mark = '<leader>sm',
      mark_motion = '<leader>mc',
      mark_visual = '<leader>mc',
      remove_mark = '<leader>md',
      cr = '<leader>s<cr>',
      interrupt = '<leader>s<space>',
      exit = '<leader>sq',
      clear = '<leader>cl',
    },
  }
  vim.keymap.set('n', '<leader>tr', function()
    if vim.bo.filetype == 'iron' then
      vim.api.nvim_win_hide(0)
    else
      iron.repl_for(vim.bo.ft)
    end
  end, { desc = 'Toggle REPL' })
end

return M
