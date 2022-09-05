local M = {}

M.sections = {
  lualine_a = {
    function()
      return 'Lsp Info'
    end,
  },
}

M.filetypes = { 'lspinfo' }

return M
