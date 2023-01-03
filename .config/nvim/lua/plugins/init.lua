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
  -- Text alignment
  { "godlygeek/tabular", cmd = "Tabularize" },
  -- Incremental rename
  {
    "smjonas/inc-rename.nvim",
    event = "UIEnter",
    config = function()
      require("inc_rename").setup {}
    end,
  },
  -- Git commands
  { "tpope/vim-fugitive", cmd = { "Git" } },

  -- UI Components
  --- Input and select
  {
    "stevearc/dressing.nvim",
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
  },
  --- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "UIEnter",
    config = function()
      require("indent_blankline").setup {
        char = "▏",
        context_char = "▏",
        show_current_context = true,
        show_current_context_start = true,
      }
    end,
  },
  -- Notification popup
  {
    "rcarriga/nvim-notify",
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
  },
  -- Editing
  --- Neovim lua
  { "folke/neodev.nvim" },
  --- Local configuration
  { "folke/neoconf.nvim" },
  --- Language server
  {
    "neovim/nvim-lspconfig",
    event = "BufEnter",
    config = function()
      require("lspconfig.ui.windows").default_options.border = "rounded"
      require("lsp").setup()
    end,
  },
  --- Auto pairs
  {
    "windwp/nvim-autopairs",
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
  },
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
  --- Tree sitter
  {
    "nvim-treesitter/playground",
    cmd = "TSPlaygroundToggle",
    config = function()
      require("nvim-treesitter.configs").setup {
        playground = {
          enable = true,
        },
      }
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    cmd = "TSContextToggle",
    config = function()
      require("treesitter-context").setup {
        -- set to false at setup,
        -- because it's loaded by TSContextToggle command
        -- and which will toggle this option
        enable = false,
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
