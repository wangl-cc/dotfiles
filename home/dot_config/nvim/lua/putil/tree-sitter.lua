local M = {}

M.langs = {}

M.langs_hl_disabled = {}

---@param langs string[]
function M.add_langs(langs) vim.list_extend(M.langs, langs) end

---@return string[] langs
function M.get_langs()
  Util.list.unique(M.langs)
  return M.langs
end

---@param langs string[]
function M.disable_hl_for(langs) vim.list_extend(M.langs_hl_disabled, langs) end

---@return string[] langs
function M.get_langs_disabled_hl()
  Util.list.unique(M.langs_hl_disabled)
  return M.langs_hl_disabled
end

return M
