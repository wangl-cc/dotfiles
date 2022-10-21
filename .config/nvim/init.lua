pcall(require, 'impatient')

-- Auto compile when there are changes in plugins.lua
local autosource = vim.api.nvim_create_augroup('AutoSource', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = { 'init.lua', 'lsp.lua', 'options.lua' },
  command = 'source <afile>',
  group = autosource,
})
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = { 'plugins.lua' },
  command = 'source <afile> | lua Packer.compile()',
  group = autosource,
})

-- plugins
Packer = require 'plugins'

-- lsp configs
LSP = require 'lsp'

-- vim options and keymaps
require 'options'

-- vim:tw=76:ts=2:sw=2:et
