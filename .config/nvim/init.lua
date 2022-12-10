pcall(require, "impatient")

-- plugin unrelated configurations
local auto_reload = require("util").auto_reload
auto_reload "options"
auto_reload "autocmds"

-- load plugins
require "plugins"

-- vim:tw=76:ts=2:sw=2:et
