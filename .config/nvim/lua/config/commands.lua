local import = require "util.import"

vim.api.nvim_create_user_command("NotesOpen", function(args)
  local name = args.fargs[1]
  require("notes").open(name)
end, {
  desc = "Open a note",
  nargs = "?",
})
vim.api.nvim_create_user_command(
  "NotesSearch",
  import("notes")["find"]:fun(),
  { desc = "Search notes" }
)
