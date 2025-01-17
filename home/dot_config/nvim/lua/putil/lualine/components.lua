local M = {}

M.uppercase_filetype = {
  function() return vim.bo.filetype:upper() end,
}

--- Case-innsensitive filetype
M.git_branch = {
  "branch",
  icon = "",
  icons_enabled = true,
}

M.git_diff = {
  "diff",
  symbols = Util.icons.diff,
  source = function()
    local gs_st = vim.b.gitsigns_status_dict
    return gs_st
      and {
        added = gs_st.added,
        modified = gs_st.changed,
        removed = gs_st.removed,
      }
  end,
}

M.diagnostics = {
  "diagnostics",
  sources = { "nvim_diagnostic" },
  sections = { "error", "warn", "info", "hint" },
  symbols = Util.icons.diagnostics,
}

M.indent = {
  function()
    if vim.bo.expandtab then
      return "Spaces: " .. vim.bo.shiftwidth
    else
      return "Tab Size: " .. vim.bo.tabstop
    end
  end,
}

M.line_width = {
  function()
    local tw = vim.bo.textwidth
    if tw == 0 then return "" end
    return tw
  end,
  icon = "LW:",
}

M.file_encoding = {
  function() return vim.bo.fileencoding:upper() end,
}

M.file_format = {
  "fileformat",
  symbols = {
    dos = "CRLF",
    unix = "LF",
    mac = "CR",
  },
}

local IGNORED_LS = {
  copilot = true,
  typos_lsp = true,
}

M.language_server = {
  function()
    local ft = vim.bo.filetype
    if ft == "" then return "" end
    local clients = vim.lsp.get_clients { bufnr = 0 }
    if vim.tbl_isempty(clients) then return "" end
    local client_names = {}
    for _, client in ipairs(clients) do
      if not IGNORED_LS[client.name] then table.insert(client_names, client.name) end
    end
    return table.concat(client_names, ", ")
  end,
  icon = "LS:",
}

M.linter = {
  function()
    local linters = vim.b.linters
    if not linters or vim.tbl_isempty(linters) then return "" end
    return table.concat(linters, ", ")
  end,
  icon = "LT:",
}

M.formatter = {
  function()
    local ft = vim.bo.filetype
    if ft == "" then return "" end
    local formatters = require("conform").list_formatters()
    local valid_formatters = {}
    for _, formatter in ipairs(formatters) do
      if formatter.available and formatter.name ~= "trim_whitespace" then
        table.insert(valid_formatters, formatter.name)
      end
    end
    return table.concat(valid_formatters, ", ")
  end,
  icon = "FMT:",
}

M.location = {
  function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local cur_line, cur_col = cursor[1], cursor[2]
    local total_lines = vim.api.nvim_buf_line_count(0)
    if cur_line == 1 then
      return string.format("%3d:%-2d Top", cur_line, cur_col)
    elseif cur_line == total_lines then
      return string.format("%3d:%-2d Bot", cur_line, cur_col)
    else
      local percent = math.floor(cur_line / total_lines * 100)
      return string.format("%3d:%-2d %2d%%%%", cur_line, cur_col, percent)
    end
  end,
}

M.time = {
  function() return os.date "%R" end,
  icon = "",
}

return M
