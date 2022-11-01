local M = {
  requires = {
    'p00f/nvim-ts-rainbow',
    'nvim-treesitter/nvim-treesitter-textobjects',
    { 'nvim-treesitter/playground', cmd = 'TSPlaygroundToggle' },
    'JoosepAlviste/nvim-ts-context-commentstring',
  },
  run = ':TSUpdate',
}

function M.config()
  require('nvim-treesitter.configs').setup {
    ensure_installed = {
      'bash',
      'vim',
      'lua',
      'regex',
      'query',
      'help',
    },
    auto_install = true,
    highlight = {
      enable = true,
    },
    indent = {
      enable = true,
    },
    rainbow = {
      enable = true,
      extended_mode = true,
    },
    playground = {
      enable = true,
    },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
          ['ab'] = '@block.outer',
          ['ib'] = '@block.inner',
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ['<leader>a'] = '@parameter.inner',
        },
        swap_previous = {
          ['<leader>A'] = '@parameter.inner',
        },
      },
    },
  }
  local parsers = require('nvim-treesitter.parsers')
  vim.keymap.set('n', '<leader>lp', function()
    local parser_list = parsers.available_parsers()
    table.sort(parser_list)
    local parser_info = {}
    for _, lang in ipairs(parser_list) do
      table.insert(parser_info, {
        lang = lang,
        status = parsers.has_parser(lang)
      })
    end
    vim.ui.select(parser_info, {
      prompt = 'Update parser',
      format_item = function(item)
        -- use + to search installed parser and - search uninstalled parser
        return string.format('%s %s', item.status and '+' or '-', item.lang)
      end,
    }, function(selected)
      if selected then
        require('nvim-treesitter.install').update()(selected.lang)
      end
    end)
  end, {
    desc = 'List tree-sitter parsers',
  })
end

return M
