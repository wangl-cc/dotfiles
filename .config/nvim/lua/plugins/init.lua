return {
  -- Lazy can manage itself
  { "folke/lazy.nvim", version = "7" },

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
  -- Git commands
  { "tpope/vim-fugitive", cmd = { "Git" } },

  --- Highlight and view todos
  {
    "folke/todo-comments.nvim",
    event = "UIEnter",
    config = function()
      require("todo-comments").setup {}
    end,
  },
  --- Copilot
  {
    "zbirenbaum/copilot.lua",
    config = function()
      require("copilot").setup {
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
      }
    end,
  },
  --- LaTeX
  {
    "lervag/vimtex",
    ft = "tex",
    cmd = "VimtexInverseSearch", -- for inverse search
    config = function()
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_reading_bar = 1
      -- NOTE: I can't disable tree-sitter, thus I must disable it here
      vim.g.vimtex_syntax_enabled = 0
      vim.g.vimtex_syntax_conceal_disable = 1
    end,
  },

  -- Misc
  --- Waka time
  { "wakatime/vim-wakatime", event = "VeryLazy" },
}

-- vim:ts=2:sw=2:et
