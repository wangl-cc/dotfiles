_G.LDU = {
  tbl = require "util.table",
  icons = require "util.icons",
  color = require "util.color",
  import = require "util.import",
  register = require "util.keymap",
}

-- plugin unrelated configurations
require "config/options"
require "config/autocmds"
require "config/commands"
require "config/keymap"

-- load plugins
require "config/manager"

-- vim:tw=76:ts=2:sw=2:et
