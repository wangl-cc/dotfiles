pcall(require, 'impatient')

-- vim options and keymaps
require('config.options')

-- load plugins
require('config.plugins')
require('config.lsp').setup()

-- vim:tw=76:ts=2:sw=2:et
