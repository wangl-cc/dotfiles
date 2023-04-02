local treesitter = {
  "nvim-treesitter/nvim-treesitter",
  event = "BufReadPre", -- Load bofore treesitter is loaded
  dependencies = {
    { "HiPhish/nvim-ts-rainbow2", version = "2" },
    "nvim-treesitter/nvim-treesitter-textobjects",
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  build = ":TSUpdate",
}

function treesitter.config()
  local rainbow = require "ts-rainbow"
  require("nvim-treesitter.configs").setup {
    ensure_installed = {
      "bash",
      "vim",
      "lua",
      "regex",
      "query",
      "help",
      "embedded_template",
      "gitcommit",
      "diff",
    },
    ignore_install = {
      "latex",
    },
    parser_install_dir = vim.fn.stdpath "config",
    auto_install = true,
    highlight = {
      enable = true,
    },
    indent = {
      enable = false,
    },
    rainbow = {
      enable = true,
      extended_mode = true,
      strategt = rainbow.strategy["local"],
      hlgroups = {
        "rainbowcol1",
        "rainbowcol2",
        "rainbowcol3",
        "rainbowcol4",
        "rainbowcol5",
        "rainbowcol6",
        "rainbowcol7",
      },
    },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["ab"] = "@block.outer",
          ["ib"] = "@block.inner",
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ["<leader>a"] = "@parameter.inner",
        },
        swap_previous = {
          ["<leader>A"] = "@parameter.inner",
        },
      },
    },
  }
  local parsers = require "nvim-treesitter.parsers"
  vim.keymap.set("n", "<leader>sp", function()
    local parser_list = parsers.available_parsers()
    table.sort(parser_list)
    local parser_info = {}
    for _, lang in ipairs(parser_list) do
      table.insert(parser_info, {
        lang = lang,
        status = parsers.has_parser(lang),
      })
    end
    vim.ui.select(parser_info, {
      prompt = "Update parser",
      format_item = function(item)
        -- use + to search installed parser and - search uninstalled parser
        return string.format("%s %s", item.status and "+" or "-", item.lang)
      end,
    }, function(selected)
      if selected then require("nvim-treesitter.install").update()(selected.lang) end
    end)
  end, { desc = "Search tree-sitter parsers" })
  local parser_config = parsers.get_parser_configs()
  parser_config.git_config = {
    install_info = {
      url = "https://github.com/the-mikedavis/tree-sitter-git-config.git",
      files = { "src/parser.c" },
      branch = "main",
    },
    filetype = "gitconfig",
  }
end

return {
  treesitter,
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
}
