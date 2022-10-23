local M = {
  opt = true,
  cmd = 'Neogit',
}
function M.config()
  require('neogit').setup {
    kind = 'vsplit',
    -- customize displayed signs
    signs = {
      -- { CLOSED, OPENED }
      section = { '', '' },
      item = { '', '' },
      hunk = { '', '' },
    },
    integrations = {
      diffview = true
    }
  }
end

return M
