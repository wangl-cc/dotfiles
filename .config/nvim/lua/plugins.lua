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

local packer = require('packer')

packer.startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  -- startup time
  use {
    'dstein64/vim-startuptime',
    opt = true,
    cmd = 'StartupTime'
  }

  -- speed up loading Lua modules
  use 'lewis6991/impatient.nvim'

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
  --- Auto tabstop and shiftwidth
  use 'tpope/vim-sleuth'

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
      vim.keymap.set({ 'n', 't', 'i', 'v', 'o' }, '<leader>te',
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
      require("tokyonight").setup {
        sidebars = { 'packer', 'toggleterm' },
      }
      vim.cmd [[colorscheme tokyonight]]
    end,
  }
  --- Statusline
  use {
    'nvim-lualine/lualine.nvim',
    requires = {
      'kyazdani42/nvim-web-devicons',
      'arkav/lualine-lsp-progress',
    },
    config = function()
      local telescope = {
        sections = { lualine_a = { 'mode' } },
        filetypes = { 'TelescopePrompt', 'TelescopeResults' },
      }
      local uppercase_filetype = function()
        return vim.bo.filetype:upper()
      end
      local filetype_only = {
        sections = { lualine_a = { uppercase_filetype } },
        filetypes = { 'lspinfo', 'packer' }
      }
      require('lualine').setup {
        options = {
          theme = 'tokyonight',
          globalstatus = true,
          component_separators = { left = '', right = '│' },
          section_separators = { left = '', right = '' },
        },
        extensions = {
          'nvim-tree',
          'quickfix',
          'toggleterm',
          telescope,
          filetype_only,
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
        },
        tabline = {
          lualine_a = {
            { 'buffers',
              show_modified_status = true,
              show_filename_only = true,
              mode = 0,
              symbols = {
                modified = ' ●', -- Text to show when the buffer is modified
                alternate_file = '', -- Text to show to identify the alternate file
                directory = '', -- Text to show when the buffer is a directory
              },
              filetype_names = {
                ['NvimTree'] = 'File Explorer',
                ['toggleterm'] = 'Terminal',
                ['packer'] = 'Packer',
                ['lspinfo'] = 'Lsp Info',
              },
            }
          },
          lualine_b = {},
          lualine_c = {},
          lualine_x = { 'lsp_progress' },
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
          map('n', '<leader>hR', gs.reset_buffer)
          map('n', '<leader>hu', gs.undo_stage_hunk)
          map('n', '<leader>hp', gs.preview_hunk)
          map('n', '<leader>hb', function() gs.blame_line { full = true } end)
          map('n', '<leader>hd', gs.diffthis)
          map('n', '<leader>hD', function() gs.diffthis('~') end)
          map('n', '<leader>tb', gs.toggle_current_line_blame)
          map('n', '<leader>td', gs.toggle_deleted)
        end,
        yadm = {
          enable = true,
        },
      }
    end
  }
  --- Telescope (fuzzy finder)
  use {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    requires = {
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
    },
    config = function()
      local actions = require("telescope.actions")
      local builtins = require("telescope.builtin")
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
      local mapopts = { noremap = true, silent = true }
      map('n', '<leader>lf', builtins.find_files, mapopts)
      map('n', '<leader>lk', builtins.keymaps, mapopts)
      map('n', '<leader>lb', builtins.buffers, mapopts)
      map('n', '<leader>lh', builtins.help_tags, mapopts)
      map('n', '<leader>lw', builtins.live_grep, mapopts)
      map('n', '<leader>lgc', builtins.git_commits, mapopts)
      map('n', '<leader>lgb', builtins.git_bcommits, mapopts)
      map('n', '<leader>lgs', builtins.git_status, mapopts)
    end
  }
  -- Code support
  --- Language server
  use 'neovim/nvim-lspconfig'
  --- Auto completion
  use {
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'dmitmel/cmp-cmdline-history',
      'zbirenbaum/copilot-cmp',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
    },
    config = function()
      local cmp = require('cmp')
      local types = require('cmp.types')
      local luasnip = require('luasnip')
      local icons = {
        Text = "",
        Method = "",
        Function = "",
        Constructor = "",
        Field = "",
        Variable = "",
        Class = "",
        Interface = "",
        Module = "",
        Property = "",
        Unit = "",
        Value = "",
        Enum = "",
        Keyword = "",
        Snippet = "",
        Color = "",
        File = "",
        Reference = "",
        Folder = "",
        EnumMember = "",
        Constant = "",
        Struct = "",
        Event = "",
        Operator = "",
        TypeParameter = "",
        Copilot = "",
      }
      cmp.setup {
        window = {
          completion = {
            col_offset = -1,
            side_padding = 0,
          },
        },
        formatting = {
          fields = { 'kind', 'abbr', 'menu' },
          format = function(_, vim_item)
            vim_item.menu = vim_item.kind
            vim_item.kind = icons[vim_item.kind] or ''
            return vim_item
          end
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
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
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              cmp.mapping.complete(fallback)
            end
          end),
          ["<C-p>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end),
          ['<CR>'] = cmp.mapping.confirm { select = true },
        },
        sources = {
          { name = 'luasnip' },
          { name = 'nvim_lsp', max_item_count = 10 },
          { name = 'copilot', max_item_count = 5 },
          { name = 'buffer', max_item_count = 5 },
          { name = 'path', max_item_count = 5 },
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
          { name = 'path', max_item_count = 5 },
          { name = 'cmdline', max_item_count = 5 },
          { name = 'cmdline_history', max_item_count = 5 },
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
              ['ab'] = '@block.outer',
              ['ib'] = '@block.inner',
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
  use {
    'nvim-treesitter/nvim-treesitter-context',
    opt = true,
    cmd = 'TSContextToggle',
    keys = '<leader>tc',
    requires = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('treesitter-context').setup {
        enable = true,
      }
      vim.keymap.set('n', '<leader>tc', '<Cmd>TSContextToggle<CR>',
        { silent = true, noremap = true })
    end,
  }
  --- Copilot
  use {
    "zbirenbaum/copilot.lua",
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
