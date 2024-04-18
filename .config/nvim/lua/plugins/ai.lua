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
    branch = "canary",
    cmd = {
      "CopilotChat",
      "CopilotChatCommit",
      "CopilotChatCommitStaged",
    },
    dependencies = "zbirenbaum/copilot.lua",
    opts = {
      window = {
        layout = "float",
        width = 0.8,
        height = 0.4,
        title = "",
        relative = "editor",
        border = "rounded",
        row = 0,
      },
    },
  },
}
