return {
  -- Lazy can manage itself
  { "folke/lazy.nvim", version = "10" },

  -- Startup time
  { "dstein64/vim-startuptime", cmd = "StartupTime" },

  -- common dependencies
  { "nvim-lua/plenary.nvim" },
  { "nvim-tree/nvim-web-devicons" },
  { "MunifTanjim/nui.nvim" },

  -- UNIX shell commands
  {
    "tpope/vim-eunuch",
    -- stylua: ignore
    cmd = {
      "Delete", "Remove", "Unlike",
      "Rename", "Move", "Copy", "Duplicate",
      "Mkdir", "Chmod", "Cfind", "Clocate", "Wall",
      "SudoWrite", "SudoEdit",
    },
  },

  -- More hover provider
  -- {
  --   "lewis6991/hover.nvim",
  --   opts = {
  --     init = function()
  --       require "hover.providers.lsp"
  --       require "hover.providers.gh"
  --       require "hover.providers.man"
  --       require "hover.providers.dictionary"
  --     end,
  --     title = false,
  --     preview_opts = {
  --       border = "rounded",
  --     },
  --   },
  -- },

  -- Waka time
  { "wakatime/vim-wakatime", event = "VeryLazy" },

  ---@type LazyPluginSpec
  {
    "wangl-cc/im-switch.nvim",
    cmd = "IMSwitch",
    dev = true,
    opts = {
      filter = false,
    },
  },
}

-- vim:ts=2:sw=2:et
