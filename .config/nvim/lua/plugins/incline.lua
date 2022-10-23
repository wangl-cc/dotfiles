local M = {}

function M.config()
  local ts_statusline = require('util.ts_statusline').ts_statusline
  local get_icon_color = require('nvim-web-devicons').get_icon_color

  require('incline').setup {
    render = function(props)
      local bufname = vim.api.nvim_buf_get_name(props.buf)
      local filename = vim.fn.fnamemodify(bufname, ':t')
      local filetype_icon, color = get_icon_color(filename)
      local status = {
        { filetype_icon, guifg = color },
        ' ',
        filename,
      }
      if vim.fn.bufnr('%') == props.buf then
        return ts_statusline {
          start = status,
          separator = ' ← ',
          reverse = true,
        }
      end
      return status
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
