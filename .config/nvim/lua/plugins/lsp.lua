return {
  "neovim/nvim-lspconfig",
  event = "BufReadPre",
  dependencies = {
    { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
    { "folke/neodev.nvim", config = true },
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    require("lspconfig.ui.windows").default_options.border = "rounded"
    require("lsp").setup()
  end,
}
