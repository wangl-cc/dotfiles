local M = {}

local auto_source_group = vim.api.nvim_create_augroup('AutoSource', { clear = true })

M.create_source_autocmd = function(opts)
  opts.group = opts.group or auto_source_group
  vim.api.nvim_create_autocmd('BufWritePost', opts)
end

function M.debug(msg, title)
  vim.notify(msg, vim.log.levels.DEBUG, { title = title or 'init.lua' })
end

function M.info(msg, title)
  vim.notify(msg, vim.log.levels.INFO, { title = title or 'init.lua' })
end

function M.warn(msg, title)
  vim.notify(msg, vim.log.levels.WARN, { title = title or 'init.lua' })
end

function M.error(msg, title)
  vim.notify(msg, vim.log.levels.ERROR, { title = title or 'init.lua' })
end

function M.unload(mod)
  package.loaded[mod] = nil
  M.debug('Unloaded ' .. mod)
end

function M.reload(mod)
  package.loaded[mod] = nil
  m = require(mod)
  M.debug('Reloaded ' .. mod)
  return m
end

return M
