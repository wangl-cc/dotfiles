local tbl = require "util.table"
local import = require "util.import"

return {
  {
    "nvimdev/indentmini.nvim",
    event = "BufEnter",
    opts = tbl.merge_options {
      char = "▏",
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    version = "3",
    cmd = "Neotree",
    dependencies = {
      "s1n7ax/nvim-window-picker",
      name = "window-picker",
      version = "2",
      opts = {
        show_prompt = false,
        picker_config = {
          statusline_winbar_picker = {
            use_winbar = "smart",
          },
        },
        filter_rules = {
          bo = {
            filetype = {
              "neo-tree",
              "Trouble",
              "notify",
              "noice",
            },
          },
        },
      },
    },
    opts = tbl.merge_options {
      close_if_last_window = true,
      popup_border_style = "rounded",
      sort_case_insensitive = true,
      use_popups_for_input = false,
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
      },
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
      default_component_configs = {
        icon = {
          folder_empty = "󰜌",
          folder_empty_open = "󰜌",
        },
        git_status = {
          symbols = {
            renamed = "󰁕",
            unstaged = "󰄱",
          },
        },
      },
    },
  },
  {
    "hkupty/iron.nvim",
    keys = {
      { "gs", mode = { "n", "v" }, desc = "Send code to REPL" },
    },
    opts = tbl.merge_options {
      config = {
        highlight_last = false,
        repl_open_cmd = function(bufnr)
          -- HACK: set the filetype to 'iron' to detect it when needed
          vim.api.nvim_buf_set_option(bufnr, "filetype", "iron")
          local win_opts = {
            number = false,
            relativenumber = false,
          }
          if vim.o.columns <= 180 then
            return require("iron.view").split.hor.botright(15, win_opts)(bufnr)
          else
            return require("iron.view").split.vert.botright(80, win_opts)(bufnr)
          end
        end,
      },
      keymaps = {
        visual_send = "gs",
        send_motion = "gs",
        send_file = "gss",
        cr = "gs<CR>",
        interrupt = "gsc",
        clear = "gsu",
        exit = "gsd",
      },
    },
    config = function(_, opts) require("iron.core").setup(opts) end,
  },
  {
    "akinsho/toggleterm.nvim",
    version = "2",
    cmd = "ToggleTerm",
    keys = {
      { "<C-t>", desc = "Toggle terminal", mode = { "n", "i" } },
    },
    opts = tbl.merge_options {
      open_mapping = "<C-t>",
      shade_terminals = false,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      direction = "float",
      float_opts = {
        border = "rounded",
        row = 0,
        col = math.floor(vim.o.columns * 0.1),
        width = math.floor(vim.o.columns * 0.8),
        height = math.floor(vim.o.lines * 0.4),
        winblend = 10,
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
    "folke/todo-comments.nvim",
    version = "1",
    event = "User ColorSchemeLoaded",
    config = true,
  },
  {
    "folke/which-key.nvim",
    version = "1",
    event = "User ColorSchemeLoaded",
    config = function(_, opts)
      local ops = require("which-key.plugins.presets").operators
      ops["gq"] = "Format"
      local wk = require "which-key"
      ---@type fun(fun: function): nil
      local user_mappings = opts.user_mappings
      opts.user_mappings = nil
      local options = tbl.merge_one({
        show_help = false,
        show_keys = false,
        plugins = {
          marks = false,
          registers = false,
          spelling = {
            enabled = true,
          },
        },
        presets = {
          z = false,
        },
        operators = {
          ga = "Align code",
          gA = "Align code with preview",
          gb = "Toggle comment blockwise",
          gc = "Toggle comment linewise",
          gs = "Send code to REPL",
          ys = "Add a surrounding pair",
          yS = "Add a surrounding pair in new line",
        },
        key_labels = {
          ["<CR>"] = "↩",
        },
        popup_mappings = {
          scroll_down = "<c-f>",
          scroll_up = "<c-b>",
        },
      }, opts)
      wk.setup(options)
      wk.register({
        -- window nav
        ["<CR>"] = "Top this line and put cursor at first non-blank",
        ["."] = "Center this line and put cursor at first non-blank",
        ["-"] = "Bottom this line and put cursor at first non-blank",
        t = "Top this line",
        z = "Center this line",
        b = "Bottom this line",
        -- spell keymaps
        ["="] = "Find spell suggestions for word under the cursor",
        g = "Mark word under the cursor as a good word permanently",
        G = "Mark word under the cursor as a good word temporarily",
        w = "Mark word under the cursor as a wrong word permanently",
        W = "Mark word under the cursor as a wrong word temporarily",
        u = {
          g = "Undo zg",
          G = "Undo zG",
          w = "Undo zw",
          W = "Undo zW",
        },
      }, { prefix = "z" })
      wk.register({
        b = { name = "buffer action" },
        c = { name = "rename target" },
        g = { name = "git action" },
        n = { name = "note action" },
        p = { name = "package manager action" },
        s = { name = "search source" },
        t = { name = "toggle target" },
        x = { name = "trouble action" },
      }, { prefix = "<leader>" })
      if user_mappings then
        for mapping in user_mappings do
          mapping(wk.register)
        end
      end
    end,
  },
  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle" },
    opts = { use_diagnostic_signs = true },
    dependencies = {
      "nvim-telescope/telescope.nvim",
      optional = true,
      opts = tbl.merge_options {
        defaults = {
          mappings = {
            i = {
              ["<c-t>"] = import("trouble.providers.telescope")
                :get("open_with_trouble")
                :callable(),
            },
          },
        },
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    opts = tbl.merge_options {
      defaults = {
        prompt_prefix = " ",
        selection_caret = " ",
        mappings = {
          i = { -- TODO: open with window picker
            ["<esc>"] = "close", -- quit but esc
            ["<C-u>"] = false, -- clear promote
            ["<C-b>"] = "preview_scrolling_up",
            ["<C-f>"] = "preview_scrolling_down",
          },
        },
        file_ignore_patterns = { "node_modules", "vendor" },
      },
    },
    config = function(_, opts)
      local telescope = require "telescope"
      telescope.setup(opts)
      for extension, _ in pairs(opts.extensions or {}) do
        telescope.load_extension(extension)
      end
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      optional = true,
      opts = tbl.merge_options {
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      },
    },
  },
}
