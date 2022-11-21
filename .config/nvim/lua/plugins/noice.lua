local M = {
  after = "tokyonight.nvim", -- wait for colorscheme to load
}

function M.config()
  local cursor_input_opts = {
    relative = "cursor",
    size = { min_width = 20 },
    position = { row = 2, col = -2 },
  }
  require("noice").setup {
    cmdline = {
      format = {
        search_down = { icon = "" },
        search_up = { icon = "" },
        help = { icon = "" },
        IncRename = {
          pattern = ":%s*IncRename%s+",
          icon = "",
          opts = cursor_input_opts,
        },
        substitute = {
          -- NOTE: a space before % to avoid this for normal sub
          pattern = [[: %%s/[\<>_%a]+/]],
          icon = "",
          opts = cursor_input_opts,
        },
        filter = { kind = "shell" },
      },
    },
    popupmenu = { enabled = false },
    notify = { enabled = true },
    smart_move = { enabled = false },
    lsp = {
      progress = { enabled = true },
      hover = { enabled = true },
      signature = { enabled = true },
    },
    messages = {
      enabled = true,
      view_search = false,
    },
    history = { view = "popup" },
    views = {
      cmdline_popup = {
        position = {
          row = "20%",
          col = "50%",
        },
      },
      confirm = {
        position = {
          row = "80%",
          col = "50%",
        },
      },
      popup = {
        border = {
          style = "rounded",
          text = {
            top = " Noice ",
            top_align = "center",
          },
        },
      },
      notify = {
        win_options = {
          winblend = 20,
        },
      },
    },
    status = {
      hunk = { find = "^Hunk %d+ of %d" },
    },
    routes = {
      {
        opts = { skip = true },
        filter = {
          any = {
            { event = "msg_show", find = "^Hunk %d+ of %d" },
            { event = "msg_show", find = "^<$" }, -- This occurs frequently but I don't know why
            { event = "msg_show", find = "^>" }, -- vim-sneak
            { event = "msg_show", find = "^RPC%[Error%]" },
          },
        },
      },
      {
        view = "notify",
        filter = {
          any = {
            { error = true },
            { event = "msg_show", find = "^Error" },
            { event = "msg_show", find = "^E%d+:" },
          },
        },
        opts = {
          title = "Error",
          level = vim.log.levels.ERROR,
          merge = false,
          replace = false,
        },
      },
      {
        view = "notify",
        filter = {
          any = {
            { warning = true },
            { event = "msg_show", find = "^Warn" },
            { event = "msg_show", find = "^W%d+:" },
            { event = "msg_show", find = "^No hunks$" },
            { event = "msg_show", find = "^not found:" }, -- vim-sneak warning
          },
        },
        opts = {
          title = "Warning",
          level = vim.log.levels.WARN,
          merge = false,
          replace = false,
        },
      },
      {
        view = "popup",
        filter = {
          any = {
            { event = "msg_history_show" },
            { event = "msg_show", min_height = 10 },
          },
        },
      },
    },
  }
end

return M
