local M = {
  opt = true,
  keys = '<C-/>',
  cmd = 'ToggleTerm',
}

function M.config()

  require('toggleterm').setup {
    size = 12,
    open_mapping = '<C-/>',
    shade_terminals = false,
    start_in_insert = true,
    insert_mappings = true,
    terminal_mappings = true,
    direction = 'float',
    float_opts = {
      border = 'rounded',
      width = math.floor(vim.o.columns * 0.8),
      height = math.floor(vim.o.lines * 0.8),
    },
    highlights = {
      NormalFloat = { link = 'NormalFloat' },
      FloatBorder = { link = 'FloatBorder' },
    },
    close_on_exit = true,
    shell = vim.o.shell,
  }
end

return M
