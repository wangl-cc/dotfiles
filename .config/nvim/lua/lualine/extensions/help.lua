local M = {}

M.sections = {
  lualine_a = {
    function()
      return 'HELP'
    end,
  },
  lualine_b = { { 'filename', file_status = false } },
  lualine_y = { 'progress' },
  lualine_z = { 'location' },
}

M.filetypes = { 'help' }

return M
