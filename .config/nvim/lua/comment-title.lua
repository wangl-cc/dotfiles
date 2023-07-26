local log = require "util.log"

local M = {}

M.options = {
  length = 70,
  fill = "-",
}

---@type table<string, table>
M.options.commentstrings = {
  julia = { "#=%s=#", len = 4, fill = "=" },
}

setmetatable(M.options.commentstrings, {
  __index = function(t, ft)
    local cstr = vim.filetype.get_option(ft, "commentstring")
    if type(cstr) == "string" and cstr ~= "" then
      if cstr:sub(-2) == "%s" then -- line comment
        local start = cstr:sub(1, -3)
        cstr = cstr .. start:reverse()
      end
      local ret = { cstr:gsub("%s", ""), len = #cstr - 2 }
      t[ft] = ret
      return ret
    else
      error("Can't get commentstrings of" .. ft)
    end
  end,
})

--- Generate a comment line with title
---@param title string Title of the comment line
---@return string line Generated comment line
local function comment_line(title)
  local len = M.options.length
  local cstr = M.options.commentstrings[vim.bo.ft]
  local res = (len - cstr.len - #title - 2) / 2
  local left = math.ceil(res)
  local right = math.floor(res)
  local fill = cstr.fill or M.options.fill
  return cstr[1]:format(fill:rep(left) .. " " .. title .. " " .. fill:rep(right))
end

--- Insert a comment title in the current line
--- If current line is not empty and tilte is not provided treat current line as title.
--- If title is provided, treat it as title, and current line must be empty.
---@param title? string
M.comment_title = function(title)
  local cur_line = vim.api.nvim_get_current_line()
  if title == nil then
    if cur_line:match "^%s*$" then
      log.error("Current line is empty and no title provided, abort", "comment-title")
    end
    title = cur_line:gsub("^%s*", ""):gsub("%s*$", "")
    vim.api.nvim_set_current_line(comment_line(title))
  else
    if cur_line:match "^%s*$" then
      vim.api.nvim_set_current_line(comment_line(title))
    end
    log.error("Current line is not empty, abort", "comment-title")
  end
end

return M
