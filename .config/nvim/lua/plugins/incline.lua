local M = {
  "b0o/incline.nvim",
  event = "UIEnter",
}

function M.config()
  local get_icon_color = require("nvim-web-devicons").get_icon_color

  require("incline").setup {
    render = function(props)
      local bufname = vim.api.nvim_buf_get_name(props.buf)
      local filename = vim.fn.fnamemodify(bufname, ":t")
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
end

return M
