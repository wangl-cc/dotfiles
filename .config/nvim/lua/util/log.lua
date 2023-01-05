local M = {}

function M.debug(msg, title)
  vim.notify(msg, vim.log.levels.DEBUG, { title = title or "init.lua" })
end

function M.info(msg, title)
  vim.notify(msg, vim.log.levels.INFO, { title = title or "init.lua" })
end

function M.warn(msg, title)
  vim.notify(msg, vim.log.levels.WARN, { title = title or "init.lua" })
end

function M.error(msg, title)
  vim.notify(msg, vim.log.levels.ERROR, { title = title or "init.lua" })
end

return M
