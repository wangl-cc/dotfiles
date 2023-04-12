---@alias notes.NuiBorderStyle "'none'" | "'single'" | "'double'" | "'rounded'" | "'solid'" | "'shadow'"
---@alias notes.TextAlign "'left'" | "'center'" | "'right'"

---@class notes.NuiBorderOptions
---@field padding number | number[] | { top: number, left: number }
---@field style notes.NuiBorderStyle | table
---@field text { top: string | boolean, top_align?: notes.TextAlign, bottom: string | boolean, bottom_align?:  notes.TextAlign}

---@alias notes.Percentage string
---@alias notes.Measure number | string

---@class notes.NuiBaseOptions
---@field ns_id? number | string
---@field enter? boolean
---@field buf_options? table<string, any>
---@field win_options? table<string, any>

---@class notes.NuiSplitOptions: notes.NuiBaseOptions
---@field position "'top'" | "'right'" | "'bottom'" | "'left'"
---@field size notes.Measure

---@class notes.NuiPopupOptions: notes.NuiBaseOptions
---@field border? notes.NuiBorderOptions | notes.NuiBorderOptions
---@field relative string | table
---@field position notes.Measure | { row: notes.Measure, col: notes.Measure }
---@field size notes.Measure | { width: notes.Measure, height: notes.Measure }
---@field focusable? boolean
---@field zindex? number
---@field bufnr? number

---@alias notes.UIMethod "'popup'" | "'split'"
---@alias notes.NuiUI NuiPopup | NuiSplit
---@alias notes.NuiOptions notes.NuiPopupOptions | notes.NuiSplitOptions

local M = {}

---@param bufnr number
---@param method notes.UIMethod
---@param opts? notes.NuiOptions
---@return notes.NuiUI
M.open = function(bufnr, method, opts)
  opts = opts or {}
  opts.bufnr = bufnr
  local UI = require("nui." .. method)
  local ui = UI(opts) ---@type notes.NuiUI
  ui.bufnr = bufnr

  ui:mount()
  return ui
end

---@param ui notes.NuiUI | nil
---@param bufnr number
---@param method notes.UIMethod
---@param shown boolean
---@param opts? notes.NuiOptions
---@return boolean shown Whether the UI was shown or not
---@return notes.NuiUI ui The UI object
M.toggle = function(ui, bufnr, method, shown, opts)
  if not ui then
    ui = M.open(bufnr, method, opts)
    return true, ui
  end
  if ui.bufnr ~= bufnr then ui.bufnr = bufnr end
  if shown then
    ui:unmount()
    return false, ui
  else
    ui:mount()
    return true, ui
  end
end

return M
