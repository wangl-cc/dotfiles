local M = {
  opt = true,
  event = 'BufEnter',
  requires = {
    {
      'kylechui/nvim-surround',
      config = function()
        require('nvim-surround').setup {}
      end
    },
    {
      'numToStr/Comment.nvim',
      config = function()
        require('Comment').setup {
          pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
        }
      end
    },
    'justinmk/vim-sneak',
  }
}

function M.config()
  -- HACK: which-key is not setup with setup() function, to clear operators
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
    key_labels = {
      ['<CR>'] = '↩',
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
    s = {
      name = 'Search', -- telescope
      t = {
        [[<Cmd>Telescope<CR>]],
        'Search telescope sources',
      },
      f = {
        [[<Cmd>Telescope find_files<CR>]],
        'Search files in CWD',
      },
      k = {
        [[<Cmd>Telescope keymaps<CR>]],
        'Search keymaps',
      },
      b = {
        [[<Cmd>Telescope buffers<CR>]],
        'Search buffers',
      },
      h = {
        [[<Cmd>Telescope help_tags<CR>]],
        'Search help tags',
      },
      w = {
        [[<Cmd>Telescope live_grep<CR>]],
        'Grep words in CWD',
      },
      c = {
        [[<Cmd>Telescope todo-comments todo<CR>]],
        'Search todo comments',
      },
    },
    g = {
      name = 'Git',
      c = {
        [[<Cmd>Telescope git_commits<CR>]],
        'Show git log'
      },
      b = {
        [[<Cmd>Telescope git_bcommits<CR>]],
        'Show git log of current file'
      },
      s = {
        [[<Cmd>Telescope git_status<CR>]],
        'Show git status'
      },
    },
    t = {
      name = 'Toggle',
      t = {
        [[<Cmd>Neotree toggle<CR>]],
        'Toggle the file explorer'
      },
      c = {
        [[<Cmd>TSContextToggle<CR>]],
        'Toggle treesitter context',
      },
      i = {
        [[<Cmd>IndentBlanklineToggle<CR>]],
        'Toggle indent guides',
      },
    },
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
  -- fold keymaps with IndentBlanklineRefresh
  local fold = {
    o = {[[zo<Cmd>IndentBlanklineRefresh<CR>]], 'Open one fold under the cursor'},
    O = {[[zO<Cmd>IndentBlanklineRefresh<CR>]], 'Open all folds under the cursor'},
    c = {[[zc<Cmd>IndentBlanklineRefresh<CR>]], 'Close one fold under the cursor'},
    C = {[[zC<Cmd>IndentBlanklineRefresh<CR>]], 'Close all folds under the cursor'},
    a = {[[za<Cmd>IndentBlanklineRefresh<CR>]], 'Toggle one fold under the cursor'},
    A = {[[zA<Cmd>IndentBlanklineRefresh<CR>]], 'Toggle all folds under the cursor'},
    v = {[[zv<Cmd>IndentBlanklineRefresh<CR>]], 'View cursor line'},
    x = {[[zx<Cmd>IndentBlanklineRefresh<CR>]], 'Re-apply fold level, then do zv'},
    X = {[[zX<Cmd>IndentBlanklineRefresh<CR>]], 'Re-apply fold level'},
    m = {[[zm<Cmd>IndentBlanklineRefresh<CR>]], 'Decrease fold level'},
    M = {[[zM<Cmd>IndentBlanklineRefresh<CR>]], 'Close all folds'},
    r = {[[zr<Cmd>IndentBlanklineRefresh<CR>]], 'Increase fold level'},
    R = {[[zR<Cmd>IndentBlanklineRefresh<CR>]], 'Open all folds'},
    n = {[[zn<Cmd>IndentBlanklineRefresh<CR>]], 'Disable fold'},
    N = {[[zN<Cmd>IndentBlanklineRefresh<CR>]], 'Enable fold'},
    i = {[[zi<Cmd>IndentBlanklineRefresh<CR>]], 'Toggle foldenable'},
  }
  wk.register(fold, { prefix = 'z' })
  -- NOTE: which-key is not compatible with vim-sneak and Comment.nvim
  -- NOTE: can't repeat with dot with treesitter textobjects
  -- bind fF and tT to sneak
  vim.keymap.set({ 'n', 'x' }, 'f', '<Plug>Sneak_f')
  vim.keymap.set({ 'n', 'x' }, 'F', '<Plug>Sneak_F')
  vim.keymap.set({ 'n', 'x' }, 't', '<Plug>Sneak_t')
  vim.keymap.set({ 'n', 'x' }, 'T', '<Plug>Sneak_T')
end

return M
