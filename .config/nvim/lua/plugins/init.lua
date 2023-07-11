return {
  -- Lazy can manage itself
  { "folke/lazy.nvim", version = "10" },

  -- Startup time
  { "dstein64/vim-startuptime", cmd = "StartupTime" },

  -- common dependencies
  { "nvim-lua/plenary.nvim" },
  { "kyazdani42/nvim-web-devicons" },
  { "MunifTanjim/nui.nvim" },

  -- Commands
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

  --- Waka time
  { "wakatime/vim-wakatime", event = "VeryLazy" },
}

-- vim:ts=2:sw=2:et
