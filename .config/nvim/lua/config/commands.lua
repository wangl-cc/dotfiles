vim.api.nvim_create_user_command("Note", function(args)
  local action = args.fargs[1]
  local scope = args.fargs[2]
  local opt
  if scope == "global" then
    opt = { scope = "global" }
  elseif scope == "project" then
    local bufname = vim.api.nvim_buf_get_name(0)
    opt = {
      scope = "project",
      path = require("notes.path").get_project_root(bufname),
    }
  elseif scope == "buffer" then
    opt = { scope = "buffer", path = vim.api.nvim_buf_get_name(0) }
  end
  if action == "open" then
    require("notes").open(opt, args.fargs[3])
  elseif action == "search" then
    require("notes").find(opt)
  end
end, {
  desc = "Open a note",
  nargs = "+",
})

vim.api.nvim_create_user_command("CommentTitle", function(args)
  local title = args.fargs[1]
  require("comment-title").comment_title(title)
end, {
  desc = "Open a note",
  nargs = "?",
})
