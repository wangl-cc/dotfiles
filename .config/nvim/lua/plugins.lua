-- install packer.nvim if not installed
local function ensure_packer()
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

local function startup(use)
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
  --- Interactive REPL
  use {
    'hkupty/iron.nvim',
    tag = '*',
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
    config = function()
      local iron = require('iron.core')
      iron.setup {
        config = {
          repl_open_cmd = function(bufnr)
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
      end, { silent = true, noremap = true })
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
          backend = { 'telescope', 'builtin' },
        }
      }
    end
  }
  --- Indent guides
  use {
    'lukas-reineke/indent-blankline.nvim',
    requires = 'nvim-treesitter',
    after = 'nvim-treesitter',
    config = function()
      require('indent_blankline').setup {
        char = '▏',
        context_char = '▏',
        show_current_context = true,
        show_current_context_start = true,
      }
      local cmds = require('indent_blankline.commands')
      vim.keymap.set('n', '<leader>ti', cmds.toggle,
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
      require('tokyonight').setup {}
      vim.cmd [[colorscheme tokyonight]]
    end,
  }
  --- Statusline
  use {
    'nvim-lualine/lualine.nvim',
    requires = {
      'kyazdani42/nvim-web-devicons',
    },
    config = function()
      local uppercase_filetype = function()
        return vim.bo.filetype:upper()
      end
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
          {
            sections = { lualine_a = { 'mode' } },
            filetypes = { 'TelescopePrompt', 'TelescopeResults' },
          },
          {
            sections = {
              lualine_a = { 'mode' },
              lualine_b = {
                { 'filename', file_status = false }
              }
            },
            filetypes = { 'iron' },
          },
          {
            sections = { lualine_a = { uppercase_filetype } },
            filetypes = { 'lspinfo', 'packer' }
          },
          {
            sections = {
              lualine_a = {
                function()
                  return 'HELP'
                end,
              },
              lualine_b = { { 'filename', file_status = false } },
              lualine_y = { 'progress' },
              lualine_z = { 'location' },
            },
            filetypes = { 'help' },
          },
          {
            sections = {
              lualine_a = {
                function()
                  return 'Playground'
                end,
              },
              lualine_y = { 'progress' },
              lualine_z = { 'location' },
            },
            filetypes = { 'tsplayground' },
          },
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
                NvimTree = 'File Explorer',
                toggleterm = 'Terminal',
                packer = 'Packer',
                lspinfo = 'Lsp Info',
                iron = 'REPL',
                tsplayground = 'Playground',
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
    requires = { 'nvim-treesitter', 'nvim-web-devicons' },
    config = function()
      local ts_statusline = require('ts_statusline')
      local get_icon_color = require('nvim-web-devicons').get_icon_color

      require('incline').setup {
        render = function(props)
          local bufname = vim.api.nvim_buf_get_name(props.buf)
          local filename = vim.fn.fnamemodify(bufname, ":t")
          local filetype_icon, color = get_icon_color(filename)
          local status = {
            { filetype_icon, guifg = color },
            ' ',
            filename,
          }
          if vim.fn.bufnr('%') == props.buf then
            return ts_statusline {
              start = status,
              separator = ' ← ',
              reverse = true,
              indicator_size = vim.fn.winwidth('%') - filename:len() - 5,
            }
          end
          return status
        end,
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
    event = { 'InsertEnter', 'CmdlineEnter' },
    requires = {
      { 'hrsh7th/cmp-nvim-lsp', after = 'nvim-cmp' },
      { 'hrsh7th/cmp-buffer', after = 'nvim-cmp' },
      { 'hrsh7th/cmp-path', after = 'nvim-cmp' },
      { 'hrsh7th/cmp-cmdline', after = 'nvim-cmp' },
      { 'dmitmel/cmp-cmdline-history', after = 'nvim-cmp' },
      { 'zbirenbaum/copilot-cmp', after = 'nvim-cmp' },
      { 'L3MON4D3/LuaSnip', after = 'nvim-cmp' },
      { 'saadparwaiz1/cmp_luasnip', after = 'nvim-cmp' },
      { 'rafamadriz/friendly-snippets', after = 'nvim-cmp' }
    },
    config = function()
      local cmp = require('cmp')
      local types = require('cmp.types')
      local luasnip = require('luasnip')
      local icons = require('icons').icons
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
          ['<C-p>'] = cmp.mapping(function(fallback)
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
      require("luasnip/loaders/from_vscode").lazy_load()
    end
  }
  --- Treesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    requires = {
      -- rainbow parentheses
      { 'p00f/nvim-ts-rainbow', after = 'nvim-treesitter' },
      { 'nvim-treesitter/nvim-treesitter-textobjects', after = 'nvim-treesitter' },
      { 'nvim-treesitter/playground', after = 'nvim-treesitter', cmd = 'TSPlaygroundToggle' },
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
        playground = {
          enable = true,
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
  --- auto pair
  use {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    after = 'nvim-cmp',
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
      local succeed, cmp = pcall(require, 'cmp')
      if succeed then
        cmp.event:on('confirm_done',
          require('nvim-autopairs.completion.cmp').on_confirm_done())
      end
    end
  }
  --- Copilot
  use {
    'zbirenbaum/copilot.lua',
    after = 'lualine.nvim',
    config = function()
      vim.defer_fn(function()
        require('copilot').setup {
          copilot_node_command = vim.loop.os_uname().sysname == 'Darwin' and
              vim.fn.expand('$HOMEBREW_PREFIX/opt/node@16/bin/node') or 'node',
        }
      end, 100)
    end
  }
  --- Zinit
  use { 'zdharma-continuum/zinit-vim-syntax', opt = true, ft = 'zsh' }

  -- Misc
  --- Waka time
  use 'wakatime/vim-wakatime'
end

packer.startup {
  startup,
  config = {
    display = {
      open_fn = function()
        local result, win, buf = require('packer.util').float {
          border = 'rounded',
        }
        vim.api.nvim_win_set_option(win, 'winhighlight', 'NormalFloat:Normal')
        return result, win, buf
      end,
    },
  }
}

if bootstrap then
  packer.sync()
end

return packer

-- vim:tw=76:ts=2:sw=2:et:fdm=expr:fdn=3
