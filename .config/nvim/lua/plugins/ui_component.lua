return {
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "UIEnter",
    config = {
      char = "▏",
      context_char = "▏",
      show_current_context = true,
      show_current_context_start = true,
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    version = "2",
    cmd = "Neotree",
    config = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      sort_case_insensitive = true,
      use_popups_for_input = false,
      window = {
        position = "left",
        width = 30,
        mappings = {
          ["<Space>"] = "noop",
          ["<CR>"] = "open_with_window_picker",
          ["s"] = "split_with_window_picker",
          ["<C-x>"] = "split_with_window_picker",
          ["S"] = "noop",
          ["v"] = "vsplit_with_window_picker",
          ["<C-v>"] = "vsplit_with_window_picker",
        },
      },
    },
  },
  {
    "TimUntersberger/neogit",
    cmd = "Neogit",
    config = {
      kind = "vsplit",
      -- customize displayed signs
      signs = {
        -- { CLOSED, OPENED }
        section = { "", "" },
        item = { "", "" },
        hunk = { "", "" },
      },
      integrations = {
        diffview = true,
      },
    },
  },
  {
    "hkupty/iron.nvim",
    keys = {
      { "<leader><CR>", mode = { "n", "v" }, desc = "Send code to REPL" },
    },
    config = function()
      require("iron.core").setup {
        config = {
          highlight_last = false,
          repl_open_cmd = function(bufnr)
            -- HACK: set the filetype to 'iron' to detect it when needed
            vim.api.nvim_buf_set_option(bufnr, "filetype", "iron")
            return require("iron.view").split.vertical.botright(80, {
              number = false,
              relativenumber = false,
            })(bufnr)
          end,
          repl_definition = {
            julia = {
              command = { "julia", "--project" },
            },
          },
        },
        keymaps = {
          visual_send = "<leader><CR>",
          send_motion = "<leader><CR>",
          send_file = "<leader><CR>gg",
          cr = "<leader><CR><CR>",
          interrupt = "<leader><C-c>",
          clear = "<leader><C-u>",
          exit = "<leader><C-d>",
        },
      }
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    cmd = "ToggleTerm",
    config = {
      size = 12,
      shade_terminals = false,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      direction = "float",
      float_opts = {
        border = "rounded",
        width = math.floor(vim.o.columns * 0.8),
        height = math.floor(vim.o.lines * 0.8),
      },
      highlights = {
        NormalFloat = { link = "NormalFloat" },
        FloatBorder = { link = "FloatBorder" },
      },
      close_on_exit = true,
      shell = vim.o.shell,
    },
  },
  {
    "b0o/incline.nvim",
    event = "UIEnter",
    config = function()
      local get_icon_color = require("nvim-web-devicons").get_icon_color
      require("incline").setup {
        render = function(props)
          local bufname = vim.api.nvim_buf_get_name(props.buf)
          local filename = vim.fs.basename(bufname)
          local filetype_icon, color = get_icon_color(filename)
          return {
            { filetype_icon, guifg = color },
            " ",
            filename,
          }
        end,
        window = {
          margin = {
            horizontal = 0,
            vertical = 0,
          },
        },
      }
    end,
  },
  {
    "folke/todo-comments.nvim",
    version = "1",
    event = "UIEnter",
    config = true,
  },
}
