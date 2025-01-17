-- TODO: add more ai related plugins, not just copilot

local status_hl = {
  [""] = "LualineGrey", -- Not yet started
  InProgress = "LualineBlue", -- In progress
  Normal = "LualineBlue", -- Ready
  Warning = "LualineYellow", -- Something is wrong
}

local lualine = require "putil.lualine"

lualine.add_component {
  function() return " " .. require("copilot.api").status.data.message end,
  cond = function()
    if not package.loaded.copilot then return false end
    local ok, clients = pcall(vim.lsp.get_clients, { name = "copilot", bufnr = 0 })
    return ok and #clients > 0
  end,
  color = function()
    local status = require("copilot.api").status.data.status or ""
    return status_hl[status]
  end,
}

return {
  "zbirenbaum/copilot.lua",
  event = "InsertEnter",
  cmd = "Copilot",
  opts = Util.tbl.merge_options {
    filetypes = {
      help = false,
      iron = false,
      toggleterm = false,
      ["*"] = true,
    },
    panel = {
      enabled = false,
    },
    suggestion = {
      enabled = true,
      auto_trigger = true,
      keymap = {
        accept = "<tab>",
        accept_word = "<c-right>",
        dismiss = "<C-]>",
      },
    },
  },
}
