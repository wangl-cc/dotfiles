local M = {}

---@class ConfirmOptions
---@field prompt string

---@param items string[] List of items to be chosen
---@param opts ConfirmOptions Options for confirm
---@param on_choice? fun(item:string, i:number) Callback when an item is chosen
---@return string item
---@return integer i
M.confirm = function(items, opts, on_choice)
  opts = opts or {}
  local i = vim.fn.confirm(opts.prompt or "Select", table.concat(items, "\n"), 0)
  if on_choice then on_choice(items[i], i) end
  return items[i], i
end

return M
