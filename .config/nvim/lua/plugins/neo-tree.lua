local M = {
  "nvim-neo-tree/neo-tree.nvim",
  version = "2",
  event = "BufEnter",
}

-- This is run this file is loaded
-- but not when this plugin is loaded
vim.g.neo_tree_remove_legacy_commands = 1

function M.config()
  require("neo-tree").setup {
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
  }
end

return M
