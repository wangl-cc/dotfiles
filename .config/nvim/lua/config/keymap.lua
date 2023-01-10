local register = require("util.keymap").register
local leader_mappings = {
  ["/"] = {
    [[<Cmd>nohlsearch<CR><Cmd>match<CR>]],
    desc = "nohlsearch and clear match",
  },
  s = {
    t = {
      [[<Cmd>Telescope<CR>]],
      desc = "Search telescope sources",
    },
    f = {
      [[<Cmd>Telescope find_files<CR>]],
      desc = "Search files in CWD",
    },
    k = {
      [[<Cmd>Telescope keymaps<CR>]],
      desc = "Search keymaps",
    },
    b = {
      [[<Cmd>Telescope buffers<CR>]],
      desc = "Search buffers",
    },
    h = {
      [[<Cmd>Telescope help_tags<CR>]],
      desc = "Search help tags",
    },
    w = {
      [[<Cmd>Telescope live_grep<CR>]],
      desc = "Grep words in CWD",
    },
    c = {
      [[<Cmd>Telescope todo-comments todo<CR>]],
      desc = "Search todo comments",
    },
    a = {
      [[<Cmd>Telescope diagnostics<CR>]],
      desc = "Search all diagnostics",
    },
  },
  g = {
    c = {
      [[<Cmd>Telescope git_commits<CR>]],
      desc = "Show git log",
    },
    b = {
      [[<Cmd>Telescope git_bcommits<CR>]],
      desc = "Show git log of current file",
    },
    s = {
      [[<Cmd>Telescope git_status<CR>]],
      desc = "Show git status",
    },
  },
  t = {
    t = {
      [[<Cmd>Neotree toggle<CR>]],
      desc = "Toggle the file explorer",
    },
    c = {
      [[<Cmd>TSContextToggle<CR>]],
      desc = "Toggle treesitter context",
    },
    p = {
      [[<Cmd>TSPlaygroundToggle<CR>]],
      desc = "Toggle treesitter playground",
    },
    i = {
      [[<Cmd>IndentBlanklineToggle<CR>]],
      desc = "Toggle indent guides",
    },
    r = {
      callback = function()
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
      desc = "Toggle REPL",
    },
  },
  c = {
    w = {
      [[: %s/\V\<<C-r><C-w>\>/<C-r><C-w>]],
      desc = "Rename all matchs of cword",
      silent = false,
    },
    W = {
      [[: %s/\V<C-r><C-a>/<C-r><C-a>]],
      desc = "Rename all matchs of cWORD",
      silent = false,
    },
  },
  p = {
    h = {
      [[<Cmd>Lazy home<CR>]],
      desc = "Home of lazy.nvim",
    },
    i = {
      [[<Cmd>Lazy install<CR>]],
      desc = "Install missing plugins",
    },
    u = {
      [[<Cmd>Lazy update<CR>]],
      desc = "Update plugins",
    },
    s = {
      [[<Cmd>Lazy sync<CR>]],
      desc = "Install, clean and update plugins",
    },
    x = {
      [[<Cmd>Lazy clean<CR>]],
      desc = "Clean unused plugins",
    },
    p = {
      [[<Cmd>Lazy profile<CR>]],
      desc = "Profile startup time",
    },
  },
}
register(leader_mappings, { prefix = "<leader>", silent = true })
-- fold keymaps with IndentBlanklineRefresh
local fold = {
  o = {
    [[zo<Cmd>IndentBlanklineRefresh<CR>]],
    desc = "Open one fold under the cursor",
  },
  O = {
    [[zO<Cmd>IndentBlanklineRefresh<CR>]],
    desc = "Open all folds under the cursor",
  },
  c = {
    [[zc<Cmd>IndentBlanklineRefresh<CR>]],
    desc = "Close one fold under the cursor",
  },
  C = {
    [[zC<Cmd>IndentBlanklineRefresh<CR>]],
    desc = "Close all folds under the cursor",
  },
  a = {
    [[za<Cmd>IndentBlanklineRefresh<CR>]],
    desc = "Toggle one fold under the cursor",
  },
  A = {
    [[zA<Cmd>IndentBlanklineRefresh<CR>]],
    desc = "Toggle all folds under the cursor",
  },
  v = { [[zv<Cmd>IndentBlanklineRefresh<CR>]], desc = "View cursor line" },
  x = {
    [[zx<Cmd>IndentBlanklineRefresh<CR>]],
    desc = "Re-apply fold level, then do zv",
  },
  X = { [[zX<Cmd>IndentBlanklineRefresh<CR>]], desc = "Re-apply fold level" },
  m = { [[zm<Cmd>IndentBlanklineRefresh<CR>]], desc = "Decrease fold level" },
  M = { [[zM<Cmd>IndentBlanklineRefresh<CR>]], desc = "Close all folds" },
  r = { [[zr<Cmd>IndentBlanklineRefresh<CR>]], desc = "Increase fold level" },
  R = { [[zR<Cmd>IndentBlanklineRefresh<CR>]], desc = "Open all folds" },
  n = { [[zn<Cmd>IndentBlanklineRefresh<CR>]], desc = "Disable fold" },
  N = { [[zN<Cmd>IndentBlanklineRefresh<CR>]], desc = "Enable fold" },
  i = { [[zi<Cmd>IndentBlanklineRefresh<CR>]], desc = "Toggle foldenable" },
}
register(fold, { prefix = "z", silent = true })
register({
  ["<C-/>"] = {
    "<Cmd>ToggleTerm<CR>",
    desc = "Toggle terminal",
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
    desc = "Send line and move down",
  },
}, { silent = true })
