local M = {}

M.sections = {
  lualine_a = {
    function()
      return 'Diagnostics'
    end,
  },
}

M.filetypes = { 'Trouble' }

return M
