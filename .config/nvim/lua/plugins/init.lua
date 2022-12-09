local config = {
  display = {
    open_fn = function()
      local result, win, buf = require("packer.util").float {
        border = "rounded",
      }
      return result, win, buf
    end,
  },
}

local function startup(use)
  -- Packer can manage itself
  use "wbthomason/packer.nvim"

  -- speed up loading Lua modules
  use "lewis6991/impatient.nvim"

  -- common dependencies
  use { "nvim-lua/plenary.nvim", opt = true, module = "plenary" }
  use { "kyazdani42/nvim-web-devicons", opt = true, module = "nvim-web-devicons" }
  use { "MunifTanjim/nui.nvim", opt = true, module = "nui" }

  -- Commands
  --- StartupTime command to measure startup time
  use {
    "dstein64/vim-startuptime",
    opt = true,
    cmd = "StartupTime",
    config = function()
      vim.g.startuptime_tries = 50
    end,
  }

  -- UNIX shell commands
  use {
    "tpope/vim-eunuch",
    opt = true,
    -- stylua: ignore
    cmd = {
      "Delete", "Remove", "Unlike",
      "Rename", "Move", "Copy", "Duplicate",
      "Mkdir", "Chmod", "Cfind", "Clocate", "Wall",
      "SudoWrite", "SudoEdit",
    },
  }
  -- Text alignment
  use { "godlygeek/tabular", opt = true, cmd = "Tabularize" }
  -- Incremental rename
  use {
    "smjonas/inc-rename.nvim",
    opt = true,
    event = "UIEnter",
    config = function()
      require("inc_rename").setup {}
    end,
  }
  -- Git commands
  use { "tpope/vim-fugitive", opt = true, cmd = { "Git" } }

  -- Colorscheme
  use { "folke/tokyonight.nvim", plugin = "tokyonight" }
  -- UI Components
  --- Git signs
  use { "lewis6991/gitsigns.nvim", plugin = "gitsigns" }
  --- Git panel
  use { "TimUntersberger/neogit", plugin = "neogit" }
  --- File explorer
  use { "nvim-neo-tree/neo-tree.nvim", plugin = "neo-tree" }
  --- Togglable terminal
  use { "akinsho/toggleterm.nvim", plugin = "toggleterm" }
  --- Interactive REPL
  use { "hkupty/iron.nvim", plugin = "iron" }
  --- Input and select
  use {
    "stevearc/dressing.nvim",
    opt = true,
    event = "UIEnter",
    config = function()
      require("dressing").setup {
        input = { enabled = false },
        select = {
          enabled = true,
          backend = { "telescope", "builtin" },
        },
      }
    end,
  }
  --- Indent guides
  use {
    "lukas-reineke/indent-blankline.nvim",
    opt = true,
    event = "UIEnter",
    config = function()
      require("indent_blankline").setup {
        char = "▏",
        context_char = "▏",
        show_current_context = true,
        show_current_context_start = true,
      }
    end,
  }
  --- Statusline
  use { "nvim-lualine/lualine.nvim", plugin = "lualine" }
  --- Floating status line
  use { "b0o/incline.nvim", plugin = "incline" }
  --- Telescope (fuzzy finder)
  use { "nvim-telescope/telescope.nvim", plugin = "telescope" }
  -- Show and define keybindings
  use { "folke/which-key.nvim", plugin = "which-key" }
  -- Notification popup
  use {
    "rcarriga/nvim-notify",
    opt = true,
    module = "notify",
    config = function()
      local notify = require "notify"
      notify.setup {
        stages = "fade",
        timeout = 3000,
        level = vim.log.levels.INFO,
        icons = {
          ERROR = "",
          WARN = "",
          INFO = "",
          DEBUG = "",
          TRACE = "✎",
        },
      }
    end,
  }
  -- UI handler for cmdline and messages
  use { "folke/noice.nvim", plugin = "noice" }

  -- Editing
  --- Neovim lua
  use { "folke/neodev.nvim", opt = true, module = "neodev" }
  --- Local configuration
  use { "folke/neoconf.nvim", opt = true, module = "neoconf" }
  --- Language server
  use {
    "neovim/nvim-lspconfig",
    opt = true,
    event = "BufEnter",
    config = function()
      require("lspconfig.ui.windows").default_options.border = "rounded"
      require("lsp").setup()
    end,
  }
  --- Auto completion
  use { "hrsh7th/nvim-cmp", plugin = "cmp" }
  --- Auto pairs
  use {
    "windwp/nvim-autopairs",
    opt = true,
    event = "InsertEnter",
    config = function()
      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      npairs.setup {}
      npairs.add_rules {
        Rule(" ", " "):with_pair(function(opts)
          local pair = opts.line:sub(opts.col - 1, opts.col)
          return vim.tbl_contains({ "()", "[]", "{}" }, pair)
        end),
        Rule("( ", " )")
            :with_pair(function()
              return false
            end)
            :with_move(function(opts)
              return opts.prev_char:match ".%)" ~= nil
            end)
            :use_key ")",
        Rule("{ ", " }")
            :with_pair(function()
              return false
            end)
            :with_move(function(opts)
              return opts.prev_char:match ".%}" ~= nil
            end)
            :use_key "}",
        Rule("[ ", " ]")
            :with_pair(function()
              return false
            end)
            :with_move(function(opts)
              return opts.prev_char:match ".%]" ~= nil
            end)
            :use_key "]",
      }
      require("cmp").event:on(
        "confirm_done",
        require("nvim-autopairs.completion.cmp").on_confirm_done()
      )
    end,
  }
  --- Highlight and view todos
  use {
    "folke/todo-comments.nvim",
    opt = true,
    event = "UIEnter",
    config = function()
      require("todo-comments").setup {}
    end,
  }
  --- Copilot
  use {
    "zbirenbaum/copilot.lua",
    opt = true,
    module = "copilot",
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
  }
  --- Tree sitter
  use { "nvim-treesitter/nvim-treesitter", plugin = "treesitter" }
  use {
    "nvim-treesitter/playground",
    opt = true,
    cmd = "TSPlaygroundToggle",
    config = function()
      require("nvim-treesitter.configs").setup {
        playground = {
          enable = true,
        },
      }
    end,
  }
  use {
    "nvim-treesitter/nvim-treesitter-context",
    opt = true,
    cmd = "TSContextToggle",
    config = function()
      require("treesitter-context").setup {
        -- set to false at setup,
        -- because it's loaded by TSContextToggle command
        -- and which will toggle this option
        enable = false,
      }
    end,
  }
  --- LaTeX
  use {
    "lervag/vimtex",
    opt = true,
    ft = "tex",
    cmd = "VimtexInverseSearch", -- for inverse search
    config = function()
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_reading_bar = 1
    end,
  }

  -- Misc
  --- Waka time
  use { "wakatime/vim-wakatime", opt = true, event = "UIEnter" }
end

return require("util.packer").setup(config, startup)

-- vim:ts=2:sw=2:et
