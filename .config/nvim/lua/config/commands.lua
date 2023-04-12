vim.api.nvim_create_user_command("NotesOpen", function(args)
  local name = args.fargs[1]
  require("notes").open(name)
end, {
  desc = "Open a note",
  nargs = "?",
})

vim.api.nvim_create_user_command(
  "TSRainbowRefresh",
  [[ exec "TSBufDisable rainbow" | exec "TSBufEnable rainbow" ]],
  { desc = "Refresh rainbow colors" }
)
