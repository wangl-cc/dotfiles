local M = {}

---@param hl_name string
---@return vim.api.keyset.hl_info?
function M.get_hl(hl_name)
  local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = false })
  return vim.tbl_isempty(hl) and nil or hl
end

function M.fg(hl_name)
  local hl = M.get_hl(hl_name)
  return hl and string.format("#%06x", hl.fg) or nil
end

function M.bg(hl_name)
  local hl = M.get_hl(hl_name)
  return hl and string.format("#%06x", hl.bg) or nil
end

return M
