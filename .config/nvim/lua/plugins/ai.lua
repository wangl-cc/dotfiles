local tbl = require "util.table"

return {
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      {
        "nvim-lualine/lualine.nvim",
        optional = true,
        opts = tbl.merge_options {
          sections = {
            lualine_x = {
              {
                function() return require("copilot.api").status.data.status end,
                icon = "",
                icon_enabled = true,
                cond = function()
                  local ok, clients =
                    pcall(vim.lsp.get_active_clients, { name = "copilot", bufnr = 0 })
                  return ok and #clients > 0
                end,
              },
            },
          },
        },
      },
    },
    cmd = "Copilot",
    opts = tbl.merge_options {
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
      },
    },
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    version = "2",
    cmd = { "CopilotChat" },
    dependencies = "zbirenbaum/copilot.lua",
    ---@type CopilotChat.config
    opts = {
      question_header = "## User",
      answer_header = "## Copilot",
      error_header = "## Error",
      separator = ":",
      show_help = false,
      selection = function(source)
        local cs = require "CopilotChat.select"
        return cs.visual(source) or cs.buffer(source)
      end,
    },
  },
}
