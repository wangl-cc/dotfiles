local M = {}

local auto_source_group = vim.api.nvim_create_augroup('AutoSource', { clear = true })

M.create_source_autocmd = function(opts)
  vim.api.nvim_create_autocmd('BufWritePost', vim.tbl_extend('force', {
    group = auto_source_group,
  }, opts))
end

M.reload = function(mod)
  package.loaded[mod] = nil
  return require(mod)
end

return M
