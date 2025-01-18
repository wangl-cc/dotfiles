-- File specific options
local M = {}

---@type table<string, boolean>
M.expand_tab_by_ft = {}
M.default_expand_tab = true

---@param ft string
function M.hard_tab(ft) M.expand_tab_by_ft[ft] = false end

---@param ft string
function M.soft_tab(ft) M.expand_tab_by_ft[ft] = true end

---@type table<string, number>
M.indent_size_by_ft = {}
M.default_indent_size = 2
---@param ft string
---@param size number
function M.indent_size(ft, size) M.indent_size_by_ft[ft] = size end

---@type table<string, number>
M.text_width_by_ft = {}
local default_text_width = 80

---@param ft string
---@param width number
function M.line_width(ft, width) M.text_width_by_ft[ft] = width end

function M.setup()
  local augroup =
    vim.api.nvim_create_augroup("lwcc_filetype_options", { clear = true })
  -- This will be override by EditorConfig, if present
  -- Because in neovim, FileType autocmd is executed before EditorConfig
  vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
      local bufnr = args.buf
      local bo = vim.bo[bufnr]

      -- Normal buffer's buftype is empty
      if bo.buftype ~= "" then return end

      local ft = bo.filetype

      local expand_tab = Util.default(M.expand_tab_by_ft[ft], M.default_expand_tab)
      bo.expandtab = expand_tab

      local indent_size = M.indent_size_by_ft[ft]
        or (expand_tab and M.default_indent_size)
      if indent_size then
        bo.tabstop = indent_size
        bo.softtabstop = indent_size
        bo.shiftwidth = indent_size
      end

      bo.textwidth = M.text_width_by_ft[ft] or default_text_width
    end,
    group = augroup,
  })
end

return M
