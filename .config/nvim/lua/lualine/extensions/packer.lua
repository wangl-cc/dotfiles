local M = {}

M.sections = {
  lualine_a = {
    function()
      return 'Packer'
    end,
  },
}

M.filetypes = { 'packer' }

return M
