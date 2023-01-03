local auto_reload = require("util").auto_reload

-- plugin unrelated configurations
auto_reload "options"
auto_reload "autocmds"

-- load plugins
auto_reload "manager"

-- vim:tw=76:ts=2:sw=2:et
