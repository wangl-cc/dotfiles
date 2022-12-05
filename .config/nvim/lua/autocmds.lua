-- set auto delete buffer for some filetypes
local auto_bd = vim.api.nvim_create_augroup("AutoDeleteBuffer", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "checkhealth" },
  callback = function()
    vim.bo.bufhidden = "delete"
  end,
  group = auto_bd,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitcommit", "gitrebase" },
  callback = function()
    vim.bo.bufhidden = "wipe"
  end,
  group = auto_bd,
})
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "lsp.log" },
  callback = function()
    vim.bo.bufhidden = "delete"
  end,
  group = auto_bd,
})

-- set tabstop and shiftwidth for some filetype
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "julia", "python" },
  callback = function()
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
  end,
  group = vim.api.nvim_create_augroup("IndentOptions", { clear = true }),
})

-- show cursor line only in active window
local cursorline = vim.api.nvim_create_augroup("CursorLine", { clear = true })
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
  group = cursorline,
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  callback = function()
    local cl = vim.wo.cursorline
    if cl then
      vim.api.nvim_win_set_var(0, "cursorline", cl)
      vim.wo.cursorline = false
    end
  end,
  group = cursorline,
})

-- treesitter for esh
local esh = vim.api.nvim_create_augroup("ESH", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "esh_*" },
  callback = function(args)
    local buffer = args.buf
    local ft = vim.bo[buffer].filetype:sub(5)
    local lang = ft == "gitconfig" and "git_config" or ft
    local scm = string.format([[
        (content) @%s @combined
        (code) @bash @combined
      ]], lang)
    vim.treesitter.query.set_query("embedded_template", "injections", scm)
    vim.treesitter.start(buffer, "embedded_template")
  end,
  group = esh
})

