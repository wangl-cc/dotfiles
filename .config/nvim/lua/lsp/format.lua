local tbl = require "util.table"
local register = require "util.keymap"

local M = {}

local format_group = vim.api.nvim_create_augroup("autofmt", { clear = true })

---@param buffer integer
---@param format fun(opts: table): nil
local function create_autocmd(buffer, format)
  vim.api.nvim_clear_autocmds {
    group = format_group,
    buffer = buffer,
  }
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = format_group,
    buffer = buffer,
    callback = function()
      if vim.b[buffer].autofmt then format { async = false } end
    end,
  })
end

local toggle_autofmt = function(buffer)
  local b = vim.b[buffer]
  if b.autofmt ~= nil then
    b.autofmt = not b.autofmt
    require("util.log").info(
      b.autofmt and "Enabled format on save" or "Disabled format on save",
      "Auto Format"
    )
  end
end

---@param client lsp.Client
---@param buffer integer
---@param autofmt boolean|nil
function M.setup(client, buffer, autofmt)
  local have_nls = #require("null-ls.sources").get_available(
    vim.bo[buffer].filetype,
    "NULL_LS_FORMATTING"
  ) > 0

  if not client.supports_method "textDocument/formatting" and not have_nls then
    return
  end

  local function format(opts)
    opts = tbl.merge_one({
      async = true,
      bufnr = buffer,
      filter = function(c)
        if have_nls then return c.name == "null-ls" end
        return c.name ~= "null-ls"
      end,
    }, opts)
    vim.lsp.buf.format(opts)
  end

  vim.b[buffer].autofmt = autofmt
  create_autocmd(buffer, format)

  local leader = {}

  ---@type KeymapSpec
  leader.f = {
    callback = format,
    desc = "Format",
  }
  ---@type KeymapSpec
  leader.tf = {
    callback = function() toggle_autofmt(buffer) end,
    desc = "Toggle autofmt",
  }

  register(leader, {
    prefix = "<leader>",
    buffer = buffer,
    silent = true,
  })
end

return M
