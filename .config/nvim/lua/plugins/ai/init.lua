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
    "jackMort/ChatGPT.nvim",
    cmd = { "ChatGPT", "ChatGPTRun" },
    opts = {
      api_host_cmd = "echo -n api.groq.com/openai",
      api_key_cmd = "security find-generic-password -w -a loong -s groq",
      actions_paths = {
        vim.fn.stdpath "config" .. "/lua/plugins/ai/actions.json",
      },
      openai_params = {
        model = "llama2-70b-4096",
        max_tokens = 4096,
      },
      openai_edit_params = {
        model = "llama2-70b-4096",
      },
    },
  },
}
