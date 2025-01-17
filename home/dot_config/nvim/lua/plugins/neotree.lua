local lualine = require "putil.lualine"

lualine.registry_extension(
  "neo-tree",
  lualine.util.with_time {
    lualine_a = {
      function() return vim.fn.fnamemodify(vim.uv.cwd() or vim.fn.getcwd(), ":~") end,
    },
  }
)

local neotree_exec = Util.import("neo-tree.command"):get "execute"

local function on_move_file(data)
  require("snacks").rename.on_rename_file(data.source, data.destination)
end

require("putil.catppuccin").add_integrations {
  neotree = true,
  window_picker = true,
}

Util.register({
  e = {
    callback = neotree_exec:closure { source = "filesystem", toggle = true },
    desc = "Toggle File Explorer",
  },
  ge = {
    callback = neotree_exec:closure { source = "git_status", toggle = true },
    desc = "Toggle Git Explorer",
  },
  be = {
    callback = neotree_exec:closure { source = "buffers", toggle = true },
    desc = "Toggle Buffer Explorer",
  },
}, { prefix = "<leader>" })

return {
  "nvim-neo-tree/neo-tree.nvim",
  version = "*",
  cmd = "Neotree",
  dependencies = {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    version = "*",
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
            "neo-tree-popup",
            "trouble",
            "noice",
            "snacks_dashboard",
            "snacks_input",
            "snacks_notif",
            "snacks_notif_history",
            "snacks_terminal",
          },
          buftype = { "terminal", "quickfix" },
        },
      },
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = { "*" },
      once = true,
      callback = function(args)
        local bufname = args.file
        local stats = vim.uv.fs_stat(bufname)
        if stats and stats.type == "directory" then
          require("neo-tree.setup.netrw").hijack()
        end
      end,
      group = vim.api.nvim_create_augroup("neo-tree-hijack", { clear = true }),
    })
  end,
  opts = {
    hide_root_node = true,
    close_if_last_window = false,
    popup_border_style = "rounded",
    sort_case_insensitive = true,
    use_popups_for_input = true,
    filesystem = {
      use_libuv_file_watcher = true,
      filtered_items = {
        hide_dotfiles = false,
      },
    },
    window = {
      position = "left",
      width = 30,
      mappings = {
        ["l"] = "open",
        ["h"] = "close_node",
        ["<CR>"] = "open_with_window_picker",
        S = "vsplit_with_window_picker",
        s = "split_with_window_picker",
        ["<C-x>"] = "split_with_window_picker",
        ["<C-v>"] = "vsplit_with_window_picker",
        ["Y"] = {
          function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg("+", path, "c")
          end,
          desc = "Copy Path to Clipboard",
        },
        ["P"] = "toggle_preview",
      },
    },
    event_handlers = {
      -- A helper function to notify lsp when a file is moved or renamed
      { event = "file_moved", handler = on_move_file },
      { event = "file_renamed", handler = on_move_file },
      -- Automatically hide and unhide cursor when entering and leaving neo tree buffer
      {
        event = "neo_tree_buffer_enter",
        handler = function() vim.cmd "highlight! Cursor blend=100" end,
      },
      {
        event = "neo_tree_buffer_leave",
        handler = function() vim.cmd "highlight! Cursor blend=0" end,
      },
    },
  },
}
