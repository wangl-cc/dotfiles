---@param name string
local function augroup(name)
  vim.api.nvim_create_augroup("lwcc_" .. name, { clear = true })
end

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup "close_with_q",
  pattern = {
    "checkhealth",
    "help",
    "man",
    "lspinfo",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd "close"
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = "Quit buffer",
      })
    end)
  end,
})

-- Show cursor line only in active window
-- There is a win variable `cursorline` to store cursorline status when disable it
-- this should avoid to enable cursorline for some window
-- where the cursorline is disable, such as Telescope prompt
local auto_cursorline = augroup "auto_cursorline"
vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  callback = function()
    local ok, cl = pcall(vim.api.nvim_win_get_var, 0, "cursorline")
    if ok and cl then
      vim.wo.cursorline = true
      vim.api.nvim_win_del_var(0, "cursorline")
    end
  end,
  group = auto_cursorline,
})
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  callback = function()
    local cl = vim.wo.cursorline
    if cl then
      vim.api.nvim_win_set_var(0, "cursorline", cl)
      vim.wo.cursorline = false
    end
  end,
  group = auto_cursorline,
})

-- Nohlsearch after entering insert mode
vim.api.nvim_create_autocmd({ "InsertEnter" }, {
  callback = function()
    if vim.v.hlsearch == 0 then return end
    local keycode = vim.api.nvim_replace_termcodes("<Cmd>nohl<CR>", true, false, true)
    vim.api.nvim_feedkeys(keycode, "n", false)
  end,
  group = augroup "nohlsearch",
})
