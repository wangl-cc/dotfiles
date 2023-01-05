local auto_reload = require("util.reload").auto_reload

-- plugin unrelated configurations
auto_reload "config/options"
auto_reload "config/autocmds"

-- load plugins
require "config/manager"

-- vim:tw=76:ts=2:sw=2:et
