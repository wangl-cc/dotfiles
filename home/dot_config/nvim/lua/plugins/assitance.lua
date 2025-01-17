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

-- TODO: more configuration

return {
  "olimorris/codecompanion.nvim",
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
  opts = {
    display = {
      chat = {
        window = {
          layout = "vertical",
          position = "right",
          width = 0.3,
        },
      },
    },
  },
}
