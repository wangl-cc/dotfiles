-- install packer.nvim if not installed
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local bootstrap = ensure_packer()

-- Auto compile when there are changes in plugins.lua
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = 'plugins.lua',
  command = 'source <afile> | PackerCompile',
  group = vim.api.nvim_create_augroup('PackerUserConfig', { clear = true })
})

local packer = require('packer')

packer.startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- Useful commands and mappings
  --- UNIX shell commands like: Remove, Delete, Rename, Move
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
  --- Git commands
  use { 'tpope/vim-fugitive', opt = true, cmd = { 'Git' } }
  --- Fuzzy finder
  use { 'junegunn/fzf', run = vim.fn['fzf#install'] }
  use 'junegunn/fzf.vim'
  --- Commenting
  use {
    'preservim/nerdcommenter',
    config = function()
      -- disable default mappings
      vim.g.NERDCreateDefaultMappings = 0
      -- use <leader>c<space> to toggle comments
      vim.keymap.set({ 'n', 'o', 'x' }, [[<leader>c<space>]],
        '<Plug>NERDCommenterToggle', { noremap = true, silent = true })
      -- add a space after comment delimiters by default
      vim.g.NERDSpaceDelims = 1
      -- align
      vim.g.NERDDefaultAlign = 'left'
      -- use compact syntax for prettified multi-line comments
      vim.g.NERDCompactSexyComs = 1
      -- enable trimming of trailing whitespace when uncommenting
      vim.g.NERDTrimTrailingWhitespace = 1
      -- enable NERDCommenterToggle to check all selected lines is commented or not
      vim.g.NERDToggleCheckAllLines = 1
    end
  }
  --- Additional text objects
  use 'wellle/targets.vim'
  --- Surrounding
  use 'tpope/vim-surround'
  --- Text alignment (not used)
  use 'godlygeek/tabular'
  --- Additional emotions
  use 'justinmk/vim-sneak'

  -- UI
  --- File explorer
  use {
    'kyazdani42/nvim-tree.lua',
    opt = true,
    keys = '<leader>te',
    cmd = 'NvimTreeToggle',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function()
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
      vim.keymap.set({'n', 't', 'i', 'v', 'o'}, '<leader>te',
        '<Cmd>NvimTreeToggle<CR>', { noremap = true, silent = true })
    end,
  }
  --- Terminal toggle
  use {
    'akinsho/toggleterm.nvim',
    tag = 'v2.*',
    opt = true,
    keys = '<leader>tt',
    config = function()
      require('toggleterm').setup {
        size = 12,
        open_mapping = [[<leader>tt]],
        shade_terminals = false,
        start_in_insert = true,
        insert_mappings = true,
        terminal_mappings = true,
        direction = 'horizontal',
        close_on_exit = true,
        shell = vim.o.shell,
      }
    end,
  }
  --- Diagnostics list
  use {
    "folke/trouble.nvim",
    opt = true,
    keys = '<leader>tp',
    cmd = 'TroubleToggle',
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup {
        position = 'bottom',
        height = 12,
        icons = true,
        signs = {
          -- icons / text used for a diagnostic
          error = '',
          warning = '',
          hint = '',
          information = '',
          other = '﫠'
        },
        use_diagnostic_signs = false
      }
      vim.keymap.set('n', '<leader>tp', '<Cmd>TroubleToggle<CR>',
        { noremap = true, silent = true })
    end
  }
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
          backend = { 'fzf', 'builtin' },
        }
      }
    end
  }
  --- Indent guides
  use {
    'lukas-reineke/indent-blankline.nvim',
    config = function()
      require("indent_blankline").setup {
        char = '│',
      }
      vim.keymap.set('n', '<leader>ti', '<Cmd>IndentBlanklineToggle<CR>',
        { noremap = true, silent = true })
      for _, keymap in pairs({ 'zo', 'zO', 'zc', 'zC', 'za', 'zA', 'zv',
        'zx', 'zX', 'zm', 'zM', 'zr', 'zR' }) do
        vim.keymap.set('n', keymap,
          keymap .. '<Cmd>IndentBlanklineRefresh<CR>',
          { noremap = true, silent = true })
      end
    end,
  }
  --- Colorscheme
  use {
    'folke/tokyonight.nvim',
    config = function()
      vim.g.tokyonight_sidebars = { 'packer', 'trouble', 'toggleterm' }
      vim.cmd [[colorscheme tokyonight]]
    end,
  }
  --- Statusline
  use {
    'nvim-lualine/lualine.nvim',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function()
      require('lualine').setup {
        options = {
          theme = 'tokyonight',
          globalstatus = true,
          component_separators = { left = '', right = '│' },
          section_separators = { left = '', right = '' },
        },
        extensions = {
          'nvim-tree',
          'fzf',
          'quickfix',
          'toggleterm',
          'trouble',
          'lspinfo',
          'packer',
          'help',
        },
        sections = {
          lualine_a = {
            { 'mode', icons_enabled = true },
          },
          lualine_b = {
            { 'branch', icons_enabled = true },
            { 'diff', symbols = { added = ' ', modified = '柳', removed = ' ' } },
            { 'filename', file_status = true, symbols = {
              modified = '●', readonly = '', new = '',
            } },
          },
          lualine_c = {
            { 'diagnostics', sources = { 'nvim_lsp' }, symbols = {
              error = '', warn = '', info = '', hint = ''
            } },
          },
          lualine_e = { 'progress' },
          lualine_f = { 'location' },
        },
        tabline = {
          lualine_a = {
            { 'buffers',
              show_modified_status = true,
              show_filename_only = true,
              mode = '2',
              symbols = {
                modified = ' ●', -- Text to show when the buffer is modified
                alternate_file = '', -- Text to show to identify the alternate file
                directory = '', -- Text to show when the buffer is a directory
              },
              filetype_names = {
                ['NvimTree'] = '',
                ['toggleterm'] = '',
                ['trouble'] = 'Diagnostics',
                ['packer'] = 'Packer',
              },
            }
          },
          lualine_b = {},
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = { 'tabs' }
        }
      }
    end
  }
  --- Floating statuslines
  use {
    'b0o/incline.nvim',
    config = function()
      require('incline').setup {
        window = {
          margin = {
            horizontal = 0,
            vertical = 0,
          },
        },
      }
    end
  }
  --- Git signs
  use {
    'lewis6991/gitsigns.nvim',
    requires = 'nvim-lua/plenary.nvim',
    config = function()
      require('gitsigns').setup {
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, { expr = true })
          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, { expr = true })
          -- Actions
          map({ 'n', 'v' }, '<leader>hs', '<Cmd>Gitsigns stage_hunk<CR>')
          map({ 'n', 'v' }, '<leader>hr', '<Cmd>Gitsigns reset_hunk<CR>')
          map('n', '<leader>hS', gs.stage_buffer)
          map('n', '<leader>hu', gs.undo_stage_hunk)
          map('n', '<leader>hR', gs.reset_buffer)
          map('n', '<leader>hp', gs.preview_hunk)
          map('n', '<leader>hb', function() gs.blame_line { full = true } end)
          map('n', '<leader>tb', gs.toggle_current_line_blame)
          map('n', '<leader>hd', gs.diffthis)
          map('n', '<leader>hD', function() gs.diffthis('~') end)
          map('n', '<leader>td', gs.toggle_deleted)
        end,
        yadm = {
          enable = true,
        },
      }
    end
  }

  -- Code support
  --- Language server
  use {
    'neovim/nvim-lspconfig',
    config = function()
      require('lsp')
    end
  }
  --- Auto completion
  use {
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'dmitmel/cmp-cmdline-history',
      "zbirenbaum/copilot-cmp",
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip'
    },
    config = function()
      local cmp = require('cmp')
      local types = require('cmp.types')
      cmp.setup {
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4)),
          ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4)),
          ['<C-n>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item({
                behavior = types.cmp.SelectBehavior.Insert
              })
            else
              cmp.mapping.complete(fallback)
            end
          end),
          ['<CR>'] = cmp.mapping.confirm { select = true },
        },
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
          { name = 'copilot' },
        },
      }
      cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' },
        },
      })
      cmp.setup.cmdline('?', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' },
        },
      })
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'path' },
          { name = 'cmdline' },
          { name = 'cmdline_history' },
        },
      })
    end
  }
  --- Treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    requires = {
      -- rainbow parentheses
      { 'p00f/nvim-ts-rainbow', after = 'nvim-treesitter' },
      { 'nvim-treesitter/nvim-treesitter-textobjects', after = 'nvim-treesitter' },
    },
    run = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
        rainbow = {
          enable = true,
          extended_mode = true,
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
              ['ib'] = '@block.inner',
              ['ab'] = '@block.outer',
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ['<leader>a'] = '@parameter.inner',
            },
            swap_previous = {
              ['<leader>A'] = '@parameter.inner',
            },
          },
        },
      }
    end,
  }
  --- Copilot
  use {
    "zbirenbaum/copilot.lua",
    event = { 'VimEnter' },
    after = 'lualine.nvim',
    config = function()
      vim.defer_fn(function()
        require("copilot").setup()
      end, 100)
    end
  }
  --- Zinit
  use { 'zdharma-continuum/zinit-vim-syntax', opt = true, ft = 'zsh' }

  -- Misc
  --- Waka time
  use 'wakatime/vim-wakatime'
end)

if bootstrap then
  packer.sync()
end

return packer

-- vim:tw=76:ts=2:sw=2:et:fdm=expr:fdn=3
