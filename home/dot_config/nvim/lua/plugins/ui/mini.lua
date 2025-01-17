Util.register({
  g = {
    [""] = { "", desc = "git" },
    c = { [[<Cmd>Git commit<CR>]], desc = "Git commit" },
    p = { [[<Cmd>Git pull<CR>]], desc = "Git pull" },
    P = { [[<Cmd>Git push<CR>]], desc = "Git push" },
  },
}, { prefix = "<leader>" })

return {
  "echasnovski/mini.nvim",
  opts = {
    align = {
      silent = true,
      mappings = {
        start = "", -- disable `ga` mapping, which is conflict with ai plugin
        start_with_preview = "gA",
      },
    },
    ai = {},
    diff = {},
    git = {},
    jump = {},
  },
  config = function(_, opts)
    for module, options in pairs(opts) do
      require("mini." .. module).setup(options)
    end
  end,
}
