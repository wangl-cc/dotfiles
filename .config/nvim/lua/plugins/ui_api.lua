--[[
This file contains the plugins that change apperence of some api
--]]

local tbl = require "util.table"

return {
  -- Better vim.ui.*
  {
    "stevearc/dressing.nvim",
    version = "1",
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load { plugins = { "dressing.nvim" } }
        return vim.ui.select(...)
      end
    end,
    opts = tbl.merge_options {
      -- vim.ui.input is handled by noice
      input = { enabled = false },
      select = {
        enabled = true,
        backend = { "telescope", "builtin" },
      },
    },
  },
  -- Better vim.notify
  {
    "rcarriga/nvim-notify",
    opts = tbl.merge_options {
      stages = "fade",
      timeout = 3000,
      level = vim.log.levels.INFO,
      icons = require("util.icons").loglevel,
      on_open = function(win) vim.api.nvim_win_set_option(win, "winblend", 10) end,
    },
  },
  -- Incremental vim.lsp.buf.rename
  {
    "smjonas/inc-rename.nvim",
    event = "UIEnter",
    config = true,
  },
  {
    "folke/noice.nvim",
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter",
        optinal = true,
        opts = tbl.merge_options {
          ensure_installed = {
            "vim",
            "lua",
            "regex",
            "markdown",
            "markdown_inline",
            "bash",
            "fish",
          },
        },
      },
      {
        "nvim-lualine/lualine.nvim",
        optinal = true,
        opts = tbl.merge_options {
          sections = {
            lualine_x = {
              {
                function() return package.loaded.noice.api.status.hunk.get() end,
                cond = function()
                  return package.loaded.noice
                    and package.loaded.noice.api.status.hunk.has()
                end,
              },
            },
          },
        },
      },
    },
    event = "UIEnter",
    version = "1",
    opts = tbl.merge_options {
      cmdline = {
        format = {
          search_down = { icon = "" },
          search_up = { icon = "" },
          help = { icon = "󰘥" },
          IncRename = {
            pattern = ":%s*IncRename%s+",
            icon = "",
            opts = {
              relative = "cursor",
              size = { min_width = 20 },
              position = { row = 2, col = -2 },
            },
          },
          substitute = {
            -- NOTE: a space before % to avoid this for normal sub
            pattern = [[: %%s/[\<>_%a]+/]],
            icon = "",
            opts = {
              relative = "cursor",
              size = { min_width = 20 },
              position = { row = 2, col = -2 },
            },
          },
          filter = {
            kind = "shell",
            lang = vim.fs.basename(vim.o.shell) == "fish" and "fish" or "bash",
          },
        },
      },
      popupmenu = { enabled = false },
      notify = { enabled = true },
      smart_move = { enabled = false },
      lsp = {
        progress = { enabled = true },
        hover = { enabled = true },
        signature = { enabled = true },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
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
        hover = {
          border = {
            style = "rounded",
            padding = { 0, 1 },
            text = {
              top = " Hover ",
              top_align = "center",
            },
          },
          position = { row = 2 },
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
    },
  },
}
