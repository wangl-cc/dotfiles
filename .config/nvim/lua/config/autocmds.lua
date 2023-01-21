local group = vim.api.nvim_create_augroup("UserCmds", { clear = true })

-- close some filetypes with <q> and auto delete buffer for some filetypes
local close_with_q = function(buf)
  vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buf, silent = true })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "checkhealth" },
  callback = function(args)
    vim.bo[args.buf].bufhidden = "delete"
    close_with_q(args.buf)
  end,
  group = group,
})
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "lsp.log", "mason.log" },
  callback = function(args)
    vim.bo[args.buf].bufhidden = "delete"
    close_with_q(args.buf)
  end,
  group = group,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitcommit", "gitrebase" },
  callback = function(args)
    vim.bo[args.buf].bufhidden = "wipe"
  end,
  group = group,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "help",
    "man",
    "tsplayground",
    "git", -- gitdiff
  },
  callback = function(args)
    close_with_q(args.buf)
  end,
  group = group,
})

-- set different tabstop and shiftwidth for some filetype
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "julia", "python" },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
  group = group,
})

-- Show cursor line only in active window
-- There is a win variable `cursorline` to store cursorline status when disable it
-- this should avoid to enable cursorline for some window
-- where the cursorline is disable, such as Telescope prompt
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  callback = function()
    local ok, cl = pcall(vim.api.nvim_win_get_var, 0, "cursorline")
    if ok and cl then
      vim.wo.cursorline = true
      vim.api.nvim_win_del_var(0, "cursorline")
    end
  end,
  group = group,
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  callback = function()
    local cl = vim.wo.cursorline
    if cl then
      vim.api.nvim_win_set_var(0, "cursorline", cl)
      vim.wo.cursorline = false
    end
  end,
  group = group,
})

-- filetype detection for esh
vim.filetype.add {
  extension = {
    gitignore = "gitignore",
  },
  filename = {
    condarc = "yaml",
    gitconfig = "gitconfig",
    [".condarc"] = "yaml",
    [".fishrc"] = "fish",
  },
  pattern = {
    [".*##template%.esh"] = function(path, _)
      local content_ft =
        vim.filetype.match { filename = path:gsub("##template%.esh", "") }
      return content_ft and "esh_" .. content_ft or "esh_unknown"
    end,
  },
}

-- treesitter for esh
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "esh_*" },
  callback = function(args)
    local buffer = args.buf
    local ft = vim.bo[buffer].filetype:sub(5)
    local lang = ft == "gitconfig" and "git_config" or ft
    local scm = string.format(
      [[
        (content) @%s @combined
        (code) @bash @combined
      ]],
      lang
    )
    vim.treesitter.query.set_query("embedded_template", "injections", scm)
    vim.treesitter.start(buffer, "embedded_template")
  end,
  group = group,
})

-- When open a directory, load neo-tree and open the directory with it
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "*" },
  once = true,
  callback = function(args)
    local bufname = args.file
    local stats = vim.loop.fs_stat(bufname)
    if stats and stats.type == "directory" then
      require("neo-tree.setup.netrw").hijack()
    end
  end,
  group = group,
})
