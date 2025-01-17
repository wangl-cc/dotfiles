local function git_notify(msg) vim.notify(msg, vim.log.levels.INFO, { title = "Git" }) end

--- Create a closure that will execute a git command asynchronously
---@param args string[]
---@return function()
local function git_cmd(args)
  return function()
    local Job = require "plenary.job"
    ---@diagnostic disable-next-line: missing-fields
    Job:new({
      command = "git",
      args = args,
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
  end
end

local leader_mappings = {
  g = {
    c = { callback = git_cmd { "commit" }, desc = "Git commit" },
    p = { callback = git_cmd { "pull" }, desc = "Git pull" },
    P = { callback = git_cmd { "push" }, desc = "Git push" },
  },
  c = {
    [""] = { "", desc = "rename" },
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
  },
}

Util.register(leader_mappings, { prefix = "<leader>", silent = true })
Util.register({
  ["<C-f>"] = function()
    if not require("noice.lsp").scroll(4) then return "<C-f>" end
  end,
  ["<C-b>"] = function()
    if not require("noice.lsp").scroll(-4) then return "<C-b>" end
  end,
}, { silent = true, expr = true })

-- Navigate with ] and [
Util.register({
  ["]"] = {
    d = { callback = vim.diagnostic.goto_next, desc = "Next diagnostic" },
    t = { [[<Cmd>tabnext<CR>]], desc = "Next tab" },
  },
  ["["] = {
    d = { callback = vim.diagnostic.goto_prev, desc = "Previous diagnostic" },
    t = { [[<Cmd>tabprevious<CR>]], desc = "Previous tab" },
  },
}, { silent = true })

-- NOTE: move to left will not trigger redraw
Util.register({
  ["<C-a>"] = "<Home>",
  ["<C-e>"] = "<End>",
  ["<C-b>"] = "<S-Left>",
  ["<C-w>"] = "<S-Right>",
}, { silent = true, mode = { "c" } })

-- Make j and k work with wrapped lines
Util.register({
  ["k"] = "gk",
  ["j"] = "gj",
  ["<Up>"] = "gk",
  ["<Down>"] = "gj",
}, { silent = true, mode = { "n", "x" } })

-- Neovide Specific Keymaps
if vim.g.neovide then
  -- Make Cmd + V work on Mac
  if vim.fn.has "mac" == 1 then
    Util.register({
      ["<D-v>"] = [[<C-R>+]],
    }, { silent = true, mode = { "i", "t", "c" } })
  end

  vim.g.neovide_scale_factor = 1.0
  local function scale(multiplier)
    return function()
      vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * multiplier
    end
  end
  local control_key = vim.fn.has "mac" == 1 and "<D-" or "<C-"
  Util.register({
    ["="] = { scale(1.25), desc = "Zoom in" },
    ["-"] = { scale(0.8), desc = "Zoom out" },
    ["0"] = { function() vim.g.neovide_scale_factor = 1.0 end, desc = "Reset zoom" },
  }, { silent = true, mode = { "n" }, prefix = control_key, suffix = ">" })
end
