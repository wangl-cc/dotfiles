local map = vim.keymap.set

local function silent(desc)
  return { silent = true, desc = desc }
end

--- mapppings
map('n', '<leader>/', [[:nohlsearch<CR>:match<CR>]], silent 'nohlsearch and clear match')
map('n', '<leader>db', [[:%s/[ \t]\+$//<CR>]], silent 'Remove trailing blanks')
map('n', '<leader>cw', [[: %s/\V\<<C-r><C-w>\>/<C-r><C-w>]], { desc = 'Change all matchs of cword' })
map('n', '<leader>cW', [[: %s/\V<C-r><C-a>/<C-r><C-a>]], { desc = 'Change all matchs of cWORD' })
