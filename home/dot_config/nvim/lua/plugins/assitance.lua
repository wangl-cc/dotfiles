Util.register {
  ["<leader>a"] = {
    [[<Cmd>CodeCompanionChat Toggle<CR>]],
    desc = "Toggle Code Companion Chat",
    mode = { "n", "v" },
  },
  ga = {
    [[<Cmd>CodeCompanionActions<CR>]],
    desc = "Code Companion Actions",
    mode = { "v" },
  },
}

return {
  "olimorris/codecompanion.nvim",
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
  adapters = {
    copilot = function()
      return require("codecompanion.adapters").extend("copilot", {
        schema = {
          model = {
            default = "claude-3.5-sonnet",
          },
        },
      })
    end,
  },
  opts = {
    display = {
      chat = {
        window = {
          layout = "vertical",
          position = "right",
          width = 0.3,
        },
        diff = {
          enabled = true,
          close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...
          layout = "vertical", -- vertical|horizontal split for default provider
          opts = {
            "internal",
            "filler",
            "closeoff",
            "algorithm:patience",
            "followwrap",
            "linematch:120",
          },
          provider = "mini_diff",
        },
      },
    },
  },
}
