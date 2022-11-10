local M = {
  opt = true,
  keys = { "<leader><CR>", [[<C-\>]] },
}
function M.config()
  local iron = require "iron.core"
  iron.setup {
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
  vim.keymap.set("n", [[<C-\>]], function()
    -- FROM: https://github.com/hkupty/iron.nvim/issues/279
    local last_line = vim.fn.line "$"
    local pos = vim.api.nvim_win_get_cursor(0)
    iron.send_line()
    vim.api.nvim_win_set_cursor(0, { math.min(pos[1] + 1, last_line), pos[2] })
  end, { desc = "Send line and move down" })
  vim.keymap.set("n", "<leader>tr", function()
    if vim.bo.filetype == "iron" then
      vim.api.nvim_win_hide(0)
    else
      iron.repl_for(vim.bo.ft)
    end
  end, { desc = "Toggle REPL" })
end

return M
