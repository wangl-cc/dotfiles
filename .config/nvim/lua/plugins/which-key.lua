local M = {
  "folke/which-key.nvim",
  event = "VeryLazy",
}

function M.config()
  require("which-key").setup {
    show_help = false,
    show_keys = false,
    plugins = {
      marks = false,
      registers = false,
      spelling = {
        enabled = true,
      },
    },
    key_labels = {
      ["<CR>"] = "↩",
    },
    popup_mappings = {
      scroll_down = "<c-f>",
      scroll_up = "<c-b>",
    },
  }
  local wk = require "which-key"
  local leader = {
    ["/"] = {
      [[:nohlsearch<CR>:match<CR>]],
      "nohlsearch and clear match",
    },
    s = {
      name = "Search", -- telescope
      t = {
        [[<Cmd>Telescope<CR>]],
        "Search telescope sources",
      },
      f = {
        [[<Cmd>Telescope find_files<CR>]],
        "Search files in CWD",
      },
      k = {
        [[<Cmd>Telescope keymaps<CR>]],
        "Search keymaps",
      },
      b = {
        [[<Cmd>Telescope buffers<CR>]],
        "Search buffers",
      },
      h = {
        [[<Cmd>Telescope help_tags<CR>]],
        "Search help tags",
      },
      w = {
        [[<Cmd>Telescope live_grep<CR>]],
        "Grep words in CWD",
      },
      c = {
        [[<Cmd>Telescope todo-comments todo<CR>]],
        "Search todo comments",
      },
      a = {
        [[<Cmd>Telescope diagnostics<CR>]],
        "Search all diagnostics",
      },
    },
    g = {
      name = "Git",
      c = {
        [[<Cmd>Telescope git_commits<CR>]],
        "Show git log",
      },
      b = {
        [[<Cmd>Telescope git_bcommits<CR>]],
        "Show git log of current file",
      },
      s = {
        [[<Cmd>Telescope git_status<CR>]],
        "Show git status",
      },
    },
    t = {
      name = "Toggle",
      t = {
        [[<Cmd>Neotree toggle<CR>]],
        "Toggle the file explorer",
      },
      c = {
        [[<Cmd>TSContextToggle<CR>]],
        "Toggle treesitter context",
      },
      i = {
        [[<Cmd>IndentBlanklineToggle<CR>]],
        "Toggle indent guides",
      },
      r = {
        function()
          local ok, iron = pcall(require, "iron.core")
          if not ok then
            return
          end
          if vim.bo.filetype == "iron" then
            vim.api.nvim_win_hide(0)
          else
            iron.repl_for(vim.bo.ft)
          end
        end,
        "Toggle REPL",
      },
    },
    c = {
      name = "Change",
      w = {
        [[: %s/\V\<<C-r><C-w>\>/<C-r><C-w>]],
        "Change all matchs of cword",
        silent = false,
      },
      W = {
        [[: %s/\V<C-r><C-a>/<C-r><C-a>]],
        "Change all matchs of cWORD",
        silent = false,
      },
    },
    h = { name = "Hunk" },
    w = { name = "Workspace folder" },
    p = {
      name = "Package manager",
      h = {
        [[<Cmd>Lazy home<CR>]],
        "Home of lazy.nvim",
      },
      i = {
        [[<Cmd>Lazy install<CR>]],
        "Install missing plugins",
      },
      u = {
        [[<Cmd>Lazy update<CR>]],
        "Update plugins",
      },
      s = {
        [[<Cmd>Lazy sync<CR>]],
        "Install, clean and update plugins",
      },
      x = {
        [[<Cmd>Lazy clean<CR>]],
        "Clean unused plugins",
      },
      p = {
        [[<Cmd>Lazy profile<CR>]],
        "Profile startup time",
      },
    },
  }
  wk.register(leader, { prefix = "<leader>" })
  -- fold keymaps with IndentBlanklineRefresh
  local fold = {
    o = {
      [[zo<Cmd>IndentBlanklineRefresh<CR>]],
      "Open one fold under the cursor",
    },
    O = {
      [[zO<Cmd>IndentBlanklineRefresh<CR>]],
      "Open all folds under the cursor",
    },
    c = {
      [[zc<Cmd>IndentBlanklineRefresh<CR>]],
      "Close one fold under the cursor",
    },
    C = {
      [[zC<Cmd>IndentBlanklineRefresh<CR>]],
      "Close all folds under the cursor",
    },
    a = {
      [[za<Cmd>IndentBlanklineRefresh<CR>]],
      "Toggle one fold under the cursor",
    },
    A = {
      [[zA<Cmd>IndentBlanklineRefresh<CR>]],
      "Toggle all folds under the cursor",
    },
    v = { [[zv<Cmd>IndentBlanklineRefresh<CR>]], "View cursor line" },
    x = {
      [[zx<Cmd>IndentBlanklineRefresh<CR>]],
      "Re-apply fold level, then do zv",
    },
    X = { [[zX<Cmd>IndentBlanklineRefresh<CR>]], "Re-apply fold level" },
    m = { [[zm<Cmd>IndentBlanklineRefresh<CR>]], "Decrease fold level" },
    M = { [[zM<Cmd>IndentBlanklineRefresh<CR>]], "Close all folds" },
    r = { [[zr<Cmd>IndentBlanklineRefresh<CR>]], "Increase fold level" },
    R = { [[zR<Cmd>IndentBlanklineRefresh<CR>]], "Open all folds" },
    n = { [[zn<Cmd>IndentBlanklineRefresh<CR>]], "Disable fold" },
    N = { [[zN<Cmd>IndentBlanklineRefresh<CR>]], "Enable fold" },
    i = { [[zi<Cmd>IndentBlanklineRefresh<CR>]], "Toggle foldenable" },
  }
  wk.register(fold, { prefix = "z" })
  wk.register {
    ["<C-/>"] = {
      "<Cmd>ToggleTerm<CR>",
      "Toggle terminal",
      mode = { "n", "v", "t" },
    },
    ["<C-\\>"] = {
      function()
        -- FROM: https://github.com/hkupty/iron.nvim/issues/279
        local last_line = vim.fn.line "$"
        local pos = vim.api.nvim_win_get_cursor(0)
        require("iron.core").send_line()
        vim.api.nvim_win_set_cursor(0, { math.min(pos[1] + 1, last_line), pos[2] })
      end,
      "Send line and move down",
    },
  }
end

return M
