local M = {}

function M.create_bufwrite_autocmd(opts)
  vim.api.nvim_create_autocmd("BufWritePost", opts)
end

local auto_reload_id = vim.api.nvim_create_augroup("AutoReload", { clear = true })
function M.auto_reload(mod)
  M.create_bufwrite_autocmd {
    pattern = mod:gsub("%.", "/") .. ".lua",
    callback = function()
      M.reload(mod)
    end,
    group = auto_reload_id,
  }
  return require(mod)
end

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

function M.unload(mod)
  package.loaded[mod] = nil
  M.info("Unloaded " .. mod)
end

function M.reload(mod)
  package.loaded[mod] = nil
  local m = require(mod)
  M.info("Reloaded " .. mod)
  return m
end

return M
