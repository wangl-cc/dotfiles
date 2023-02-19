local M = {}

local log = require "util.log"

function M.create_bufwrite_autocmd(opts)
  vim.api.nvim_create_autocmd("BufWritePost", opts)
end

local auto_reload_id = vim.api.nvim_create_augroup("AutoReload", { clear = true })
---@param mod string Module to be auto reloaded
---@return any Module
function M.auto_reload(mod)
  M.create_bufwrite_autocmd {
    pattern = mod:gsub("%.", "/") .. ".lua",
    callback = function() M.reload(mod) end,
    group = auto_reload_id,
  }
  return require(mod)
end

---@param mod string Module to be unloaded
function M.unload(mod)
  package.loaded[mod] = nil
  log.info("Unloaded " .. mod)
end

---@param mod string Module to be reloaded
function M.reload(mod)
  package.loaded[mod] = nil
  local m = require(mod)
  log.info("Reloaded " .. mod)
  return m
end

return M
