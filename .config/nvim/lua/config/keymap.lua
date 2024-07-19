local register = require "util.keymap"
local import = require "util.import"

local lazygit = nil

local notes = import "notes"
local notes_find = notes:get "find"
local notes_toggle = notes:get "toggle"

local copilot_chat = import "CopilotChat"

local bd = import("mini.bufremove"):get "delete"
local bufferline = import "bufferline"
local groups = import "bufferline.groups"

local function git_notify(msg) vim.notify(msg, vim.log.levels.INFO, { title = "Git" }) end

local leader_mappings = {
  f = {
    callback = import("conform"):get("format"):with {
      async = true,
      lsp_fallback = true,
    },
    desc = "Format current buffer",
  },
  b = {
    d = { bd:with(0, false), desc = "Remove current buffer" },
    D = { bd:with(0, true), desc = "Force remove current buffer" },
    p = {
      callback = groups:get("toggle_pin"):with(),
      desc = "Pin current buffer",
    },
    P = {
      callback = groups:get("action"):with("ungrouped", "close"),
      desc = "Clear all ungrouped buffers",
    },
    g = { bufferline:get("pick"):with(), desc = "Pick a buffer" },
    G = { bufferline:get("close_with_pick"):with(), desc = "Pick a buffer to close" },
  },
  s = {
    t = { [[<Cmd>Telescope<CR>]], desc = "Search telescope sources" },
    f = { [[<Cmd>Telescope find_files<CR>]], desc = "Search files in CWD" },
    k = { [[<Cmd>Telescope keymaps<CR>]], desc = "Search keymaps" },
    b = { [[<Cmd>Telescope buffers<CR>]], desc = "Search buffers" },
    h = { [[<Cmd>Telescope help_tags<CR>]], desc = "Search help tags" },
    w = { [[<Cmd>Telescope live_grep<CR>]], desc = "Grep words in CWD" },
    c = { [[<Cmd>Telescope todo-comments todo<CR>]], desc = "Search todo comments" },
    a = { [[<Cmd>Telescope diagnostics<CR>]], desc = "Search all diagnostics" },
    n = {
      g = {
        callback = notes_find:with { scope = "global" },
        desc = "Search global notes",
      },
      p = {
        callback = notes_find:with_fun(function()
          local bufname = vim.api.nvim_buf_get_name(0)
          local project = require("notes.path").get_project_root(bufname)
          return { scope = "project", path = project }
        end),
        desc = "Search project notes",
      },
      b = {
        callback = notes_find:with_fun(
          function() return { scope = "buffer", path = vim.api.nvim_buf_get_name(0) } end
        ),
        desc = "Search buffer notes",
      },
    },
    p = {
      callback = function()
        local parsers = require "nvim-treesitter.parsers"
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
          if selected then
            require("nvim-treesitter.install").update()(selected.lang)
          end
        end)
      end,
      desc = "Search a tree-sitter parser to update",
    },
  },
  g = {
    c = {
      callback = function()
        local Job = require "plenary.job"
        ---@diagnostic disable-next-line: missing-fields
        Job:new({
          command = "git",
          args = { "commit" },
          cwd = vim.fn.getcwd(),
          env = {
            HOME = vim.env.HOME,
            PATH = vim.env.PATH,
            GIT_EDITOR = "nvr -cc split --remote-wait",
            NVIM = vim.v.servername,
          },
          on_stdout = function(_, data) git_notify(data) end,
          on_stderr = function(_, data) git_notify(data) end,
        }):start()
      end,
      desc = "Git commit",
    },
    p = {
      callback = function()
        git_notify "Pushing..."
        local Job = require "plenary.job"
        ---@diagnostic disable-next-line: missing-fields
        Job:new({
          command = "git",
          args = { "push" },
          cwd = vim.fn.getcwd(),
          env = {
            PATH = vim.env.PATH,
          },
          on_stdout = function(_, data) git_notify(data) end,
          on_stderr = function(_, data) git_notify(data) end,
        }):start()
      end,
      desc = "Git push",
    },
    P = {
      function()
        local Job = require "plenary.job"
        ---@diagnostic disable-next-line: missing-fields
        Job:new({
          command = "git",
          args = { "pull" },
          cwd = vim.fn.getcwd(),
          env = {
            PATH = vim.env.PATH,
          },
          on_stdout = function(_, data) git_notify(data) end,
          on_stderr = function(_, data) git_notify(data) end,
        }):start()
      end,
      desc = "Git pull",
    },
    l = { [[<Cmd>Telescope git_commits<CR>]], desc = "Show git log" },
    f = {
      [[<Cmd>Telescope git_bcommits<CR>]],
      desc = "Show git log of current file",
    },
    s = { [[<Cmd>Telescope git_status<CR>]], desc = "Show git status" },
    b = { [[<Cmd>Telescope git_branches<CR>]], desc = "Show git branches" },
    g = {
      callback = function()
        if not lazygit then
          lazygit = require("toggleterm.terminal").Terminal:new {
            cmd = "lazygit",
            hidden = true,
            float_opts = {
              border = "rounded",
              row = function() return math.floor(vim.o.lines * 0.1) end,
              col = function() return math.floor(vim.o.columns * 0.1) end,
              width = function() return math.floor(vim.o.columns * 0.8) end,
              height = function() return math.floor(vim.o.lines * 0.8) end,
            },
          }
        end
        lazygit:toggle()
      end,
      desc = "Open lazygit terminal",
    },
  },
  t = {
    t = { [[<Cmd>Neotree toggle<CR>]], desc = "Toggle the file explorer" },
    c = { [[<Cmd>TSContextToggle<CR>]], desc = "Toggle treesitter context" },
    r = {
      callback = function()
        local ok, iron = pcall(require, "iron.core")
        if not ok then return end
        if vim.bo.filetype == "iron" then
          vim.api.nvim_win_hide(0)
        else
          iron.repl_for(vim.bo.ft)
        end
      end,
      desc = "Toggle REPL",
    },
    p = {
      callback = import("CopilotChat"):get("toggle"):with(),
      desc = "Toggle CopilotChat",
    },
  },
  c = {
    w = {
      [[: %s/\V\<<C-r><C-w>\>/<C-r><C-w>]],
      desc = "Rename all matches of cword",
      silent = false,
    },
    W = {
      [[: %s/\V<C-r><C-a>/<C-r><C-a>]],
      desc = "Rename all matches of cWORD",
      silent = false,
    },
    t = {
      callback = copilot_chat:get("toggle"):with(),
      desc = "Toggle Copilot Chat",
    },
    c = {
      callback = copilot_chat:get("toggle"):with {
        window = {
          layout = "float",
          width = 1,
          height = 1,
          border = "none",
        },
      },
      desc = "Open a full screen Copilot Chat",
    },
  },
  p = {
    h = { [[<Cmd>Lazy home<CR>]], desc = "Home of lazy.nvim" },
    i = { [[<Cmd>Lazy install<CR>]], desc = "Install missing plugins" },
    u = { [[<Cmd>Lazy update<CR>]], desc = "Update plugins" },
    s = { [[<Cmd>Lazy sync<CR>]], desc = "Install, clean and update plugins" },
    x = { [[<Cmd>Lazy clean<CR>]], desc = "Clean unused plugins" },
    p = { [[<Cmd>Lazy profile<CR>]], desc = "Profile startup time" },
  },
  n = {
    g = {
      callback = notes_toggle:with({ scope = "global" }, "main"),
      desc = "Toggle main global notes",
    },
    p = {
      callback = notes_toggle:with_fun(function()
        local bufname = vim.api.nvim_buf_get_name(0)
        local project = require("notes.path").get_project_root(bufname)
        local name = project:match "([^/]+)/$"
        return { scope = "project", path = project }, name
      end),
      desc = "Toggle mail project notes",
    },
    b = {
      callback = notes_toggle:with_fun(function()
        local bufname = vim.api.nvim_buf_get_name(0)
        local name = bufname:match "([^/]+)$"
        return { scope = "buffer", path = bufname }, name
      end),
      desc = "Toggle mail buffer notes",
    },
  },
}

local trouble = import "trouble"
---@type Import.LazySub
local trouble_toggle = trouble:get "toggle"

leader_mappings.x = {
  x = { callback = trouble_toggle:with(), desc = "Open trouble" },
  w = {
    callback = trouble_toggle:with { mode = "workspace_diagnostics" },
    desc = "Open trouble in workspace mode",
  },
  d = {
    callback = trouble_toggle:with { mode = "document_diagnostics" },
    desc = "Open trouble in document mode",
  },
  q = {
    callback = trouble_toggle:with { mode = "quickfix" },
    desc = "Open trouble in quickfix mode",
  },
  l = {
    callback = trouble_toggle:with { mode = "loclist" },
    desc = "Open trouble in loclist mode",
  },
}

register(leader_mappings, { prefix = "<leader>", silent = true })
register({
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
register({
  ["<C-f>"] = function()
    if not require("noice.lsp").scroll(4) then return "<C-f>" end
  end,
  ["<C-b>"] = function()
    if not require("noice.lsp").scroll(-4) then return "<C-b>" end
  end,
}, { silent = true, expr = true })

local cycle = bufferline:get "cycle"
-- Navigate with ] and [
register({
  ["]"] = {
    b = {
      cycle:with(1),
      desc = "Next buffer",
    },
    d = {
      callback = vim.diagnostic.goto_next,
      desc = "Next diagnostic",
    },
    t = {
      [[<Cmd>tabnext<CR>]],
      desc = "Next tab",
    },
    x = {
      callback = trouble:get("next"):with { skip_groups = true, jump = true },
      desc = "Next trouble",
    },
  },
  ["["] = {
    b = {
      cycle:with(-1),
      desc = "Previous buffer",
    },
    d = {
      callback = vim.diagnostic.goto_prev,
      desc = "Previous diagnostic",
    },
    t = {
      [[<Cmd>tabprevious<CR>]],
      desc = "Previous tab",
    },
    x = {
      callback = trouble:get("previous"):with { skip_groups = true, jump = true },
      desc = "Previous trouble",
    },
  },
}, { silent = true })

-- ISSUE: move to left will not trigger redraw
register({
  ["<C-a>"] = "<Home>",
  ["<C-e>"] = "<End>",
  ["<C-b>"] = "<S-Left>",
  ["<C-w>"] = "<S-Right>",
}, { silent = true, mode = { "c" } })

register({
  ["<Up>"] = "gk",
  ["<Down>"] = "gj",
}, { silent = true, mode = { "n", "x" } })
