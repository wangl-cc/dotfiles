if vim.fn.executable('bash-language-server') ~= 1 then
  return
end

local M = {}

M.options = {
  filetypes = { 'bash', 'sh' }
}

return M
