local group = vim.api.nvim_create_augroup("UserCmds", { clear = true })

-- close some filetypes with <q> and auto delete buffer for some filetypes
local close_with_q = function(buf)
  vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buf, silent = true })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "checkhealth", "man" },
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
  callback = function(args) vim.bo[args.buf].bufhidden = "wipe" end,
  group = group,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "help",
    "tsplayground",
    "startuptime",
    "git", -- gitdiff
  },
  callback = function(args) close_with_q(args.buf) end,
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
    typ = "typst",
  },
  filename = {
    condarc = "yaml",
    [".condarc"] = "yaml",
    [".fishrc"] = "fish",
  },
  pattern = {
    [".*##template%.esh"] = function(path)
      local content_ft =
        vim.filetype.match { filename = path:gsub("##template%.esh", "") }
      if not content_ft then return "esh" end
      local lang = vim.treesitter.language.get_lang(content_ft)
      local scm = string.format(
        [[
            ((content) @injection.content
             (#set! injection.language "%s")
             (#set! injection.combined))

            ((code) @injection.content
             (#set! injection.language "bash")
             (#set! injection.combined))
          ]],
        lang
      )
      return "esh",
        function(bufnr)
          vim.treesitter.query.set("embedded_template", "injections", scm)
          vim.treesitter.start(bufnr, "embedded_template")
        end
    end,
  },
}

-- filetype specific settings
--- file types that use 4 spaces for indentation
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "julia", "rust" },
  callback = function(args)
    local bufnr = args.buf
    local bo = vim.bo[bufnr]
    bo.expandtab = true
    bo.shiftwidth = 4
    bo.softtabstop = 4
    if bo.filetype == "julia" then
      bo.textwidth = 92
    elseif bo.filetype == "rust" then
      bo.textwidth = 100
    end
  end,
  group = group,
})
--- file types that use tab for indentation
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitconfig", "make" },
  callback = function(args)
    local bufnr = args.buf
    local bo = vim.bo[bufnr]
    bo.expandtab = false
    bo.shiftwidth = 8
    bo.softtabstop = 8
    bo.tabstop = 8
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

-- When open a quickfix window, load trouble and open the quickfix window with it
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "qf" },
  callback = function()
    local ok, trouble = pcall(require, "trouble")
    if ok then
      -- Check whether we deal with a quickfix or location list buffer, close the window and open the
      -- corresponding Trouble window instead.
      if vim.fn.getloclist(0, { filewinid = 1 }).filewinid ~= 0 then
        vim.defer_fn(function()
          vim.cmd.lclose()
          trouble.open "loclist"
        end, 0)
      else
        vim.defer_fn(function()
          vim.cmd.cclose()
          if not vim.tbl_isempty(vim.fn.getqflist()) then trouble.open "quickfix" end
        end, 0)
      end
    end
  end,
  group = group,
})

-- Nohlsearch after entering insert mode
vim.api.nvim_create_autocmd({ "InsertEnter" }, {
  callback = function()
    if vim.v.hlsearch == 0 then return end
    local keycode = vim.api.nvim_replace_termcodes("<Cmd>nohl<CR>", true, false, true)
    vim.api.nvim_feedkeys(keycode, "n", false)
  end,
  group = group,
})
