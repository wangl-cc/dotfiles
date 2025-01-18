local M = {}

---@param msg string
---@param title? string
function M.debug(msg, title)
  vim.notify(msg, vim.log.levels.DEBUG, { title = title or "DEBUG" })
end

---@param msg string
---@param title? string
function M.info(msg, title)
  vim.notify(msg, vim.log.levels.INFO, { title = title or "INFO" })
end

---@param msg string
---@param title? string
function M.warn(msg, title)
  vim.notify(msg, vim.log.levels.WARN, { title = title or "WARN" })
end

---@param msg string
---@param title? string
function M.error(msg, title)
  vim.notify(msg, vim.log.levels.ERROR, { title = title or "ERROR" })
end

return M
