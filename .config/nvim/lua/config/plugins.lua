local config = {
  display = {
    open_fn = function()
      local result, win, buf = require('packer.util').float {
        border = 'rounded',
      }
      return result, win, buf
    end,
  },
}

local function startup(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- startup time
  use {
    'dstein64/vim-startuptime',
    opt = true,
    cmd = 'StartupTime',
    config = function()
      vim.g.startuptime_tries = 50
    end
  }

  -- common dependencies
  use { 'nvim-lua/plenary.nvim', opt = true, module = 'plenary' }
  use { 'kyazdani42/nvim-web-devicons', opt = true, module = 'nvim-web-devicons' }

  -- speed up loading Lua modules
  use 'lewis6991/impatient.nvim'

  -- UNIX shell commands
  use {
    'tpope/vim-eunuch',
    opt = true,
    cmd = {
      'Delete', 'Remove', 'Unlike',
      'Rename', 'Move', 'Copy', 'Duplicate',
      'Mkdir', 'Chmod', 'Cfind', 'Clocate', 'Wall',
      'SudoWrite', 'SudoEdit',
    }
  }
  -- Git commands
  use { 'tpope/vim-fugitive', opt = true, cmd = { 'Git' } }
  --- Git signs
  use { 'lewis6991/gitsigns.nvim', plugin = 'gitsigns' }
  -- Git panel
  use { 'TimUntersberger/neogit', plugin = 'neogit' }
  --- Commenting
  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup {}
    end
  }
  --- Surrounding
  use {
    'kylechui/nvim-surround',
    config = function()
      require('nvim-surround').setup {}
    end
  }
  --- Text alignment (not used)
  use 'godlygeek/tabular'
  --- Enhance search
  use {
    'justinmk/vim-sneak',
    config = function()
      vim.keymap.set({ 'n', 'x' }, 'f', '<Plug>Sneak_f')
      vim.keymap.set({ 'n', 'x' }, 'F', '<Plug>Sneak_F')
      vim.keymap.set({ 'n', 'x' }, 't', '<Plug>Sneak_t')
      vim.keymap.set({ 'n', 'x' }, 'T', '<Plug>Sneak_T')
    end
  }
  --- Better repeat with .
  use 'tpope/vim-repeat'
  --- Auto tabstop and shiftwidth
  use 'tpope/vim-sleuth'
  --- Incremental rename
  use {
    'smjonas/inc-rename.nvim',
    config = function()
      require('inc_rename').setup {}
    end
  }

  -- UI
  --- File explorer
  use { 'kyazdani42/nvim-tree.lua', plugin = 'nvim-tree' }
  --- Terminal toggle
  use { 'akinsho/toggleterm.nvim', plugin = 'toggleterm' }
  --- Interactive REPL
  use { 'hkupty/iron.nvim', plugin = 'iron' }
  --- Input and select
  use {
    'stevearc/dressing.nvim',
    config = function()
      require('dressing').setup {
        input = {
          enable = true,
          start_in_insert = true,
          mappings = {
            n = {
              ['<C-c>'] = 'Close',
              ['<CR>'] = 'Confirm',
            },
            i = {
              ['<C-c>'] = 'Close',
              ['<CR>'] = 'Confirm',
              ['<Up>'] = 'HistoryPrev',
              ['<Down>'] = 'HistoryNext',
            },
          },
        },
        select = {
          enabled = true,
          backend = { 'telescope', 'builtin' },
        }
      }
    end
  }
  --- Indent guides
  use {
    'lukas-reineke/indent-blankline.nvim',
    config = function()
      require('indent_blankline').setup {
        char = '▏',
        context_char = '▏',
        show_current_context = true,
        show_current_context_start = true,
      }
      local cmds = require('indent_blankline.commands')
      vim.keymap.set('n', '<leader>ti', cmds.toggle,
        { desc = 'Toggle indent guides' })
      for _, keymap in pairs({ 'zo', 'zO', 'zc', 'zC', 'za', 'zA', 'zv',
        'zx', 'zX', 'zm', 'zM', 'zr', 'zR' }) do
        vim.keymap.set('n', keymap,
          keymap .. '<Cmd>IndentBlanklineRefresh<CR>',
          { noremap = true, silent = true })
      end
    end,
  }
  --- Colorscheme
  use { 'folke/tokyonight.nvim', plugin = 'tokyonight' }
  --- Statusline
  use { 'nvim-lualine/lualine.nvim', plugin = 'lualine' }
  --- Floating status line
  use { 'b0o/incline.nvim', plugin = 'incline' }
  --- Telescope (fuzzy finder)
  use { 'nvim-telescope/telescope.nvim', plugin = 'telescope' }
  -- WhichKey (keybindings)
  use {
    'folke/which-key.nvim',
    config = function()
      local wk = require('which-key')
      wk.setup {
        show_help = false,
        show_keys = false,
        plugins = {
          spelling = {
            enabled = true,
          },
        },
        popup_mappings = {
          scroll_down = '<c-f>',
          scroll_up = '<c-b>',
        }
      }
      wk.register {
        ['<leader>'] = {
          l = {
            name = 'List',
            g = { name = 'Git' },
          },
          t = { name = 'Toggle' },
          g = { name = 'Go to' },
          m = { name = 'Mark' },
          s = { name = 'Send' },
          c = { name = 'Change' },
          h = { name = 'Hunk' },
          d = { name = 'Remove' },
          a = { name = 'Add' },
        }
      }
    end
  }
  -- Notify (notifications)
  use {
    'rcarriga/nvim-notify',
    config = function()
      local notify = require('notify')
      notify.setup {
        stages = 'fade',
        timeout = 3000,
        level = vim.log.levels.INFO,
        icons = {
          ERROR = '',
          WARN  = '',
          INFO  = '',
          DEBUG = '',
          TRACE = '✎',
        },
      }
    end
  }
  -- cmdline and handle messages
  use { 'folke/noice.nvim', plugin = 'noice' }
  -- Code support
  --- Language server
  use {
    'neovim/nvim-lspconfig',
    config = function()
      -- This is just config for ui, config for lsp in config/lsp.lua
      -- we can't load lsp.lua here because it may break packer compile
      require('lspconfig.ui.windows').default_options.border = 'rounded'
    end
  }
  --- Auto completion
  use { 'hrsh7th/nvim-cmp', plugin = 'cmp' }
  --- Snippets
  use {
    'L3MON4D3/LuaSnip',
    opt = true,
    event = { 'InsertEnter', 'CmdLineEnter' },
    module = 'luasnip',
    requires = 'rafamadriz/friendly-snippets',
    config = function()
      require('luasnip/loaders/from_vscode').lazy_load()
    end
  }
  --- Tree sitter
  use { 'nvim-treesitter/nvim-treesitter', plugin = 'treesitter' }
  use {
    'nvim-treesitter/nvim-treesitter-context',
    opt = true,
    cmd = 'TSContextToggle',
    keys = '<leader>tc',
    config = function()
      require('treesitter-context').setup {
        enable = true,
      }
      vim.keymap.set('n', '<leader>tc', '<Cmd>TSContextToggle<CR>',
        { silent = true, noremap = true, desc = 'Toggle treesitter context' })
    end,
  }
  --- auto pair
  use {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      local npairs = require('nvim-autopairs')
      local Rule = require('nvim-autopairs.rule')
      npairs.setup {}
      npairs.add_rules {
        Rule(' ', ' ')
            :with_pair(function(opts)
              local pair = opts.line:sub(opts.col - 1, opts.col)
              return vim.tbl_contains({ '()', '[]', '{}' }, pair)
            end),
        Rule('( ', ' )')
            :with_pair(function() return false end)
            :with_move(function(opts)
              return opts.prev_char:match('.%)') ~= nil
            end)
            :use_key(')'),
        Rule('{ ', ' }')
            :with_pair(function() return false end)
            :with_move(function(opts)
              return opts.prev_char:match('.%}') ~= nil
            end)
            :use_key('}'),
        Rule('[ ', ' ]')
            :with_pair(function() return false end)
            :with_move(function(opts)
              return opts.prev_char:match('.%]') ~= nil
            end)
            :use_key(']')
      }
      require('cmp').event:on('confirm_done',
        require('nvim-autopairs.completion.cmp').on_confirm_done())
    end
  }
  --- Copilot
  use {
    'zbirenbaum/copilot.lua',
    config = function()
      require('copilot').setup {
        copilot_node_command = vim.loop.os_uname().sysname == 'Darwin' and
            vim.fn.expand('$HOMEBREW_PREFIX/opt/node@16/bin/node') or 'node',
        filetypes = {
          help = false,
          ['*'] = true,
        },
        panel = {
          enabled = false,
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
        },
      }
    end
  }
  --- Zinit
  use { 'zdharma-continuum/zinit-vim-syntax', opt = true, ft = 'zsh' }
  --- LaTeX
  use {
    'lervag/vimtex',
    opt = true,
    ft = 'tex',
    cmd = 'VimtexInverseSearch', -- for inverse search
    config = function()
      vim.g.vimtex_view_method = 'skim'
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_reading_bar = 1
    end
  }
  -- Neovim lua
  use { 'folke/neodev.nvim', opt = true, module = 'neodev' }

  -- Misc
  --- Waka time
  use { 'wakatime/vim-wakatime', opt = true, event = 'VimEnter' }
end

return require('util.packer').setup(config, startup)

-- vim:ts=2:sw=2:et
