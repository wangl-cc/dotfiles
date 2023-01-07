local M = {}

M.loglevel = vim.log.levels.DEBUG

---@param msg string
---@param title? string
function M.debug(msg, title)
  if M.loglevel <= vim.log.levels.DEBUG then
    vim.notify(msg, vim.log.levels.DEBUG, { title = title or "DEBUG" })
  end
end

---@param msg string
---@param title? string
function M.info(msg, title)
  if M.loglevel <= vim.log.levels.INFO then
    vim.notify(msg, vim.log.levels.INFO, { title = title or "INFO" })
  end
end

---@param msg string
---@param title? string
function M.warn(msg, title)
  if M.loglevel <= vim.log.levels.WARN then
    vim.notify(msg, vim.log.levels.WARN, { title = title or "WARN" })
  end
end

---@param msg string
---@param title? string
function M.error(msg, title)
  if M.loglevel <= vim.log.levels.ERROR then
    vim.notify(msg, vim.log.levels.ERROR, { title = title or "ERROR" })
  end
end

return M
