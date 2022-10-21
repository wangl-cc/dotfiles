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
        '<Plug>NERDCommenterToggle', { noremap = true, silent = true,
        desc = 'Change comment state' })
      -- add a space after comment delimiters by default
      vim.g.NERDSpaceDelims = 1
      -- align
      vim.g.NERDDefaultAlign = 'left'
      -- use compact syntax for prettified multi-line comments
      vim.g.NERDCompactSexyComs = 1
      -- enable trimming of trailing white space when uncomment
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
  --- Enhance search
  use {
    'justinmk/vim-sneak',
    opt = true,
    keys = { 's', 'S', 'f', 'F', 't', 'T' },
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
        '<Cmd>NvimTreeToggle<CR>', { noremap = true, silent = true,
        desc = 'Toggle the file explorer' })
    end,
  }
  --- Terminal toggle
  use {
    'akinsho/toggleterm.nvim',
    tag = 'v2.*',
    opt = true,
    keys = '<leader>tt',
    cmd = 'ToggleTerm',
    config = function()
      require('toggleterm').setup {
        size = 12,
        open_mapping = [[<leader>tt]],
        shade_terminals = false,
        start_in_insert = true,
        insert_mappings = true,
        terminal_mappings = true,
        direction = 'float',
        float_opts = {
          border = 'rounded',
          width = math.floor(vim.o.columns * 0.8),
          height = math.floor(vim.o.lines * 0.8),
        },
        highlights = {
          NormalFloat = { link = 'NormalFloat' },
          FloatBorder = { link = 'FloatBorder' },
        },
        close_on_exit = true,
        shell = vim.o.shell,
      }
    end,
  }
  --- Interactive REPL
  use {
    'hkupty/iron.nvim',
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
      end, { desc = 'Toggle REPL' })
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
  use {
    'folke/tokyonight.nvim',
    config = function()
      local is_sshr = vim.env.SSHR_PORT ~= nil
      local cmd_core = 'defaults read -g AppleInterfaceStyle'
      local cmd_full
      if is_sshr then
        cmd_full = { 'ssh', vim.env.LC_HOST, '-o', 'StrictHostKeyChecking=no',
          '-p', vim.env.SSHR_PORT, cmd_core }
      else
        cmd_full = vim.fn.split(cmd_core)
      end

      local function can_autobg()
        return vim.fn.has('mac') == 1 or (is_sshr and vim.env.LC_OS == 'Darwin')
      end

      local function is_dark()
        return vim.fn.systemlist(cmd_full)[1] == 'Dark'
      end

      local tokyonight = require('tokyonight.config')
      tokyonight.setup {
        sidebars = { 'qf' },
        on_highlights = function(hl, c)
          hl.rainbowcol6 = { fg = c.magenta2 }
        end,
      }
      vim.cmd [[colorscheme tokyonight]]
      require('autobg').setup {
        can_autobg = can_autobg,
        is_dark = is_dark,
      }
    end,
  }
  --- icons
  use 'kyazdani42/nvim-web-devicons'
  --- Statusline
  use {
    'nvim-lualine/lualine.nvim',
    requires = {
      'kyazdani42/nvim-web-devicons',
    },
    after = {
      'noice.nvim', -- after noice to ensure status line functions are loaded
      'gitsigns.nvim', -- after gitsigns to ensure b.gitsigns_status_dict is seted
    },
    config = function()
      local uppercase_filetype = function()
        return vim.bo.filetype:upper()
      end
      local noice = require('noice').api.statusline
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
            { 'diff', symbols = { added = ' ', modified = '柳', removed = ' ' },
              source = function()
                local gs_st = vim.b.gitsigns_status_dict
                return gs_st and { added = gs_st.added, modified = gs_st.changed, removed = gs_st.removed }
              end },
            { 'filename', file_status = true, symbols = {
              modified = '●', readonly = '', new = '',
            } },
          },
          lualine_c = {
            { 'diagnostics', sources = { 'nvim_lsp' }, symbols = {
              error = '', warn = '', info = '', hint = ''
            } },
          },
          lualine_x = {
            {
              noice.hunk.get,
              cond = noice.hunk.has,
            },
            {
              noice.sneak.get,
              cond = noice.sneak.has,
            },
            { 'searchcount' },
            { 'encoding' },
            { 'fileformat' },
            { 'filetype' },
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
                lspinfo = 'LSP Info',
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
  --- Floating status line
  use {
    'b0o/incline.nvim',
    requires = {
      'nvim-treesitter/nvim-treesitter',
      'kyazdani42/nvim-web-devicons',
    },
    config = function()
      local ts_statusline = require('ts_statusline').ts_statusline
      local get_icon_color = require('nvim-web-devicons').get_icon_color

      require('incline').setup {
        render = function(props)
          local bufname = vim.api.nvim_buf_get_name(props.buf)
          local filename = vim.fn.fnamemodify(bufname, ':t')
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
        current_line_blame_opts = {
          delay = 100,
        },
        diff_opts = {
          internal = true,
        },
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
          end, { expr = true, desc = 'Next change hunk' })
          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, { expr = true, desc = 'Previous change hunk' })
          -- Actions
          map({ 'n', 'v' }, '<leader>hs', '<Cmd>Gitsigns stage_hunk<CR>',
            { desc = 'Stage hunk' })
          map({ 'n', 'v' }, '<leader>hr', '<Cmd>Gitsigns reset_hunk<CR>',
            { desc = 'Reset hunk' })
          map('n', '<leader>hS', gs.stage_buffer, { desc = 'Stage buffer' })
          map('n', '<leader>hR', gs.reset_buffer, { desc = 'Reset buffer' })
          map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'Undo stage hunk' })
          map('n', '<leader>hp', gs.preview_hunk, { desc = 'Preview hunk' })
          map('n', '<leader>hb', function() gs.blame_line { full = true } end,
            { desc = 'Blame line' })
          map('n', '<leader>hd', gs.diffthis, { desc = 'Diff against the index' })
          map('n', '<leader>hD', function() gs.diffthis('~') end, { desc = 'Diff against the last commit' })
          map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'Toggle blame of current line' })
          map('n', '<leader>td', gs.toggle_deleted, { desc = 'Toggle deleted lines' })
          map('n', '<leader>ts', gs.toggle_signs, { desc = 'Toggle git signcolumn' })
          map('n', '<leader>tl', gs.toggle_linehl, { desc = 'Toggle git line highlight' })
          map('n', '<leader>tw', gs.toggle_word_diff, { desc = 'Toggle word diff' })
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
      map('n', '<leader>lf', builtins.find_files, { desc = 'List files in CWD' })
      map('n', '<leader>lk', builtins.keymaps, { desc = 'List keymaps' })
      map('n', '<leader>lb', builtins.buffers, { desc = 'List buffers' })
      map('n', '<leader>lh', builtins.help_tags, { desc = 'List help tags' })
      map('n', '<leader>lw', builtins.live_grep, { desc = 'Live grep' })
      map('n', '<leader>lgc', builtins.git_commits, { desc = 'Show git log' })
      map('n', '<leader>lgb', builtins.git_bcommits, { desc = 'Show git log of current file' })
      map('n', '<leader>lgs', builtins.git_status, { desc = 'Show git status' })
    end
  }
  -- WhichKey (keybindings)
  use {
    'folke/which-key.nvim',
    config = function()
      local wk = require('which-key')
      wk.setup {
        plugins = {
          spelling = {
            enabled = true,
          },
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
  use {
    'folke/noice.nvim',
    requires = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    },
    config = function()
      require('noice').setup {
        cmdline = {
          format = {
            search_down = { icon = '' },
            search_up = { icon = '' },
            -- lua don't support pattern like h(elp)? or (h|help)
            -- thus :h and :help are separated
            h = { kind = 'help', pattern = ':%s*h%s+', icon = '' },
            help = { pattern = ':%s*help%s+', icon = '' },
            filter = { kind = 'shell' },
          },
        },
        popupmenu = { enabled = false },
        notify = { enabled = true },
        lsp_progress = { enabled = true },
        messages = {
          enabled = true,
          view_search = false,
        },
        history = { view = 'popup' },
        views = {
          cmdline_popup = {
            position = {
              row = '20%',
              col = '50%',
            }
          },
          confirm = {
            position = {
              row = '80%',
              col = '50%',
            }
          },
          popup = {
            border = {
              style = 'rounded',
              text = {
                top = ' Noice ',
                top_align = 'center',
              }
            },
          },
        },
        status = {
          hunk = { find = '^Hunk %d+ of %d' },
          sneak = { find = '^>' },
        },
        routes = {
          {
            opts = { skip = true },
            filter = {
              any = {
                { event = 'msg_show', find = '^Hunk %d+ of %d' },
                { event = 'msg_show', find = 'go up one level' },
                { event = 'msg_show', find = '^<$' }, -- This occurs frequently but I don't know why
                { event = 'msg_show', find = '^>' }, -- vim-sneak
              }
            }
          },
          {
            view = 'notify',
            filter = {
              any = {
                { error = true },
                { event = 'msg_show', find = '^Error' },
                { event = 'msg_show', find = '^E%d+:' },
                { event = 'msg_show', find = '^RPC%[Error%]' },
              }
            },
            opts = {
              title = 'Error',
              level = vim.log.levels.ERROR,
              merge = false,
              replace = false,
            }
          },
          {
            view = 'notify',
            filter = {
              any = {
                { warning = true },
                { event = 'msg_show', find = '^Warn' },
                { event = 'msg_show', find = '^W%d+:' },
                { event = 'msg_show', find = '^No hunks$' },
                { event = 'msg_show', find = '^not found:' }, -- vim-sneak warning
              }
            },
            opts = {
              title = 'Warning',
              level = vim.log.levels.WARN,
              merge = false,
              replace = false,
            }
          },
          {
            view = 'popup',
            filter = {
              any = {
                { event = 'msg_history_show' },
                { min_height = 10 },
              }
            }
          },
        }
      }
    end
  }
  -- Code support
  --- Language server
  use {
    'neovim/nvim-lspconfig',
    config = function()
      -- This is just config for ui, config for lsp in lsp.lua
      require('lspconfig.ui.windows').default_options.border = 'rounded'
    end
  }
  --- Auto completion
  use {
    'hrsh7th/nvim-cmp',
    event = { 'InsertEnter', 'CmdlineEnter' },
    after = { 'nvim-lspconfig', 'LuaSnip' },
    requires = {
      { 'hrsh7th/cmp-nvim-lsp', after = 'nvim-cmp' },
      { 'hrsh7th/cmp-buffer', after = 'nvim-cmp' },
      { 'hrsh7th/cmp-path', after = 'nvim-cmp' },
      { 'hrsh7th/cmp-cmdline', after = 'nvim-cmp' },
      { 'dmitmel/cmp-cmdline-history', after = 'nvim-cmp' },
      { 'L3MON4D3/LuaSnip' },
      { 'saadparwaiz1/cmp_luasnip', after = 'nvim-cmp' },
      { 'hrsh7th/cmp-omni', after = 'nvim-cmp' },
    },
    config = function()
      local cmp = require('cmp')
      local types = require('cmp.types')
      local luasnip = require('luasnip')
      local icons = require('icons').icons
      local copilot = require('copilot.suggestion')
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
          -- <Tab> and <S-Tab> are similar to <C-n> and <C-p>
          -- But <Tab> can trigger copilot suggestion while <C-n> not
          -- And <C-n> can trigger complete while <Tab> not
          ['<Tab>'] = cmp.mapping(function(fallback)
            if copilot.is_visible() then
              copilot.accept()
            elseif cmp.visible() then
              cmp.select_next_item({
                behavior = types.cmp.SelectBehavior.Insert
              })
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
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
        -- TODO: source priority
        sources = {
          { name = 'luasnip' },
          { name = 'omni' },
          { name = 'nvim_lsp', max_item_count = 10 },
          { name = 'buffer', max_item_count = 5 },
          { name = 'path', max_item_count = 5 },
        },
      }
      cmp.setup.cmdline({ '/', '?' }, {
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
      local parsers = require('nvim-treesitter.parsers')
      vim.keymap.set('n', '<leader>lp', function()
        local parser_list = parsers.available_parsers()
        table.sort(parser_list)
        local parser_info = {}
        for _, lang in ipairs(parser_list) do
          table.insert(parser_info, {
            lang = lang,
            status = parsers.has_parser(lang)
          })
        end
        vim.ui.select(parser_info, {
          prompt = 'Update parser',
          format_item = function(item)
            -- use + to search installed parser and - search uninstalled parser
            return string.format('%s %s', item.status and '+' or '-', item.lang)
          end,
        }, function(selected)
          if selected then
            require('nvim-treesitter.install').update()(selected.lang)
          end
        end)
      end, {
        desc = 'List tree-sitter parsers',
      })
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
        { silent = true, noremap = true, desc = 'Toggle treesitter context' })
    end,
  }
  --- auto pair
  use {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    after = 'nvim-cmp',
    require = 'hrsh7th/nvim-cmp',
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
    after = 'lualine.nvim',
    config = function()
      vim.defer_fn(function()
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
      end, 100)
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

  -- Misc
  --- Waka time
  use {
    'wakatime/vim-wakatime',
    opt = true,
    event = 'VimEnter',
  }
end

packer.startup {
  startup,
  config = {
    display = {
      open_fn = function()
        local result, win, buf = require('packer.util').float {
          border = 'rounded',
        }
        return result, win, buf
      end,
    },
    disable_commands = true,
  }
}

if bootstrap then
  packer.sync()
end

return packer

-- vim:tw=76:ts=2:sw=2:et
