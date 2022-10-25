local M = {
  requires = {
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',
  },
}

function M.config()
  require('noice').setup {
    cmdline = {
      format = {
        search_down = { icon = '' },
        search_up = { icon = '' },
        help = { icon = '' },
        -- issues about IncRename adn Substitute:
        -- 1. can't restore if the popup has different pos (fixed by 8463b0b)
        -- 2. cursor don't update during move (fixed by unknown commit or upstream)
        IncRename = {
          pattern = ':%s*IncRename%s+',
          icon = '',
          opts = {
            relative = 'cursor',
            size = { min_width = 15 },
            position = { row = -3, col = -4 },
          }
        },
        substitute = {
          pattern = [[: %%s/[\<>%a]+/]], -- a space before % to avoid this for normal sub
          icon = '',
          opts = {
            relative = 'cursor',
            size = { min_width = 15 },
            position = { row = -3, col = -4 },
          }
        },
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
            { event = 'msg_show', find = '^<$' }, -- This occurs frequently but I don't know why
            { event = 'msg_show', find = '^>' }, -- vim-sneak
            { event = 'msg_show', find = '^RPC%[Error%]' },
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

return M
