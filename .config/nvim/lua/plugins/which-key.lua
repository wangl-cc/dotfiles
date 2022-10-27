local M = {
  requires = {
    'kylechui/nvim-surround',
    'numToStr/Comment.nvim',
    'justinmk/vim-sneak',
  }
}

function M.config()
  -- this is hacky, to remove the operators gc defined by which-key default
  require('which-key.config').setup {
    show_help = false,
    show_keys = false,
    plugins = {
      marks = false,
      registers = false,
      spelling = {
        enabled = true,
      },
    },
    popup_mappings = {
      scroll_down = '<c-f>',
      scroll_up = '<c-b>',
    }
  }
  local options = require('which-key.config').options
  options.operators = {}
  local wk = require('which-key')
  wk.load()
  local leader = {
    ['/'] = {
      [[:nohlsearch<CR>:match<CR>]],
      'nohlsearch and clear match'
    },
    l = {
      name = 'List',
      g = { name = 'Git' },
    },
    t = { name = 'Toggle' },
    g = { name = 'Go to' },
    m = { name = 'Mark' },
    s = { name = 'Send' },
    c = {
      name = 'Change',
      w = {
        [[: %s/\V\<<C-r><C-w>\>/<C-r><C-w>]],
        'Change all matchs of cword',
        silent = false
      },
      W = {
        [[: %s/\V<C-r><C-a>/<C-r><C-a>]],
        'Change all matchs of cWORD',
        silent = false
      },
    },
    h = { name = 'Hunk' },
    w = { name = 'Workspace folder' },
  }
  wk.register(leader, { prefix = '<leader>' })
  -- known issue:
  -- which-key is not compatible the below plugins
  -- thus key like gc will not trigger wihch-key
  require('nvim-surround').setup {}
  -- known issue: can't repeat with dot with treesitter textobjects
  require('Comment').setup {
    pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
  }
  -- sneak
  vim.keymap.set({ 'n', 'x' }, 'f', '<Plug>Sneak_f')
  vim.keymap.set({ 'n', 'x' }, 'F', '<Plug>Sneak_F')
  vim.keymap.set({ 'n', 'x' }, 't', '<Plug>Sneak_t')
  vim.keymap.set({ 'n', 'x' }, 'T', '<Plug>Sneak_T')
end

return M
