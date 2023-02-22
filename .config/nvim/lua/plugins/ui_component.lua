return {
  {
    "lukas-reineke/indent-blankline.nvim",
    version = "2",
    event = "UIEnter",
    opts = {
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
    opts = {
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
    opts = {
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
    opts = {
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
  {
    "folke/which-key.nvim",
    version = "1",
    event = "UIEnter",
    config = function()
      local wk = require "which-key"
      wk.setup {
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
          ["<CR>"] = "↩",
        },
        popup_mappings = {
          scroll_down = "<c-f>",
          scroll_up = "<c-b>",
        },
      }
      wk.register({
        s = { name = "Search source" },
        g = { name = "Git source" },
        t = { name = "Toggle target" },
        c = { name = "Rename target" },
        h = { name = "Hunk action" },
        w = { name = "Workspace action" },
        p = { name = "Package manager action" },
      }, { prefix = "<leader>" })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function() require("telescope").load_extension "fzf" end,
    },
    config = function()
      local telescope = require "telescope"
      local actions = require "telescope.actions"
      telescope.setup {
        defaults = {
          mappings = {
            i = { -- TODO: open with window picker
              ["<esc>"] = actions.close, -- quit but esc
              ["<C-u>"] = false, -- clear promote
              ["<C-b>"] = actions.preview_scrolling_up,
              ["<C-f>"] = actions.preview_scrolling_down,
            },
          },
          file_ignore_patterns = { "node_modules", "vendor" },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      }
    end,
  },
}
