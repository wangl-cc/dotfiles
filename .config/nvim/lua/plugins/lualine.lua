local M = {
  after = {
    'noice.nvim', -- after noice to ensure status line functions are loaded
    'gitsigns.nvim', -- after gitsigns to ensure b.gitsigns_status_dict is seted
  },
}

function M.config()
  local uppercase_filetype = function()
    return vim.bo.filetype:upper()
  end
  local noice = require('noice').api.status
  require('lualine').setup {
    options = {
      theme = 'tokyonight',
      globalstatus = true,
      component_separators = { left = '', right = '│' },
      section_separators = { left = '', right = '' },
    },
    extensions = {
      'nvim-tree',
      'quickfix',
      'toggleterm',
      {
        sections = { lualine_a = { 'mode' } },
        filetypes = { 'TelescopePrompt', 'TelescopeResults' },
      },
      {
        sections = {
          lualine_a = { 'mode' },
          lualine_b = {
            { 'filename', file_status = false }
          }
        },
        filetypes = { 'iron' },
      },
      {
        sections = { lualine_a = { uppercase_filetype } },
        filetypes = { 'lspinfo', 'packer' }
      },
      {
        sections = {
          lualine_a = {
            function()
              return 'HELP'
            end,
          },
          lualine_b = { { 'filename', file_status = false } },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        filetypes = { 'help' },
      },
      {
        sections = {
          lualine_a = {
            function()
              return 'Playground'
            end,
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        filetypes = { 'tsplayground' },
      },
    },
    sections = {
      lualine_a = {
        { 'mode', icons_enabled = true },
      },
      lualine_b = {
        { 'branch', icons_enabled = true },
        { 'diff', symbols = { added = ' ', modified = '柳', removed = ' ' },
          source = function()
            local gs_st = vim.b.gitsigns_status_dict
            return gs_st and { added = gs_st.added, modified = gs_st.changed, removed = gs_st.removed }
          end },
        { 'filename', file_status = true, symbols = {
          modified = '●', readonly = '', new = '',
        } },
      },
      lualine_c = {
        { 'diagnostics', sources = { 'nvim_lsp' }, symbols = {
          error = '', warn = '', info = '', hint = ''
        } },
      },
      lualine_x = {
        {
          noice.hunk.get,
          cond = noice.hunk.has,
        },
        {
          noice.sneak.get,
          cond = noice.sneak.has,
        },
        {
          function()
            if vim.v.hlsearch == 0 then
              return ''
            end
            local result = vim.fn.searchcount { timeout = 500, maxcount = 99 }
            if result.total == 0 or result.current == 0 then
              return ''
            end
            local pattern = vim.fn.escape(vim.fn.getreg('/'), '%')
            if result.incomplete == 1 then
              return string.format('/%s [?/?]', pattern)
            elseif result.incomplete == 2 then
              if result.current > result.maxcount then
                return string.format('/%s [>%d/>%d]', pattern, result.current, result.total)
              else
                return string.format('/%s [%d/>%d]', pattern, result.current, result.total)
              end
            else
              return string.format('/%s [%d/%d]', pattern, result.current, result.total)
            end
          end
        },
        { 'encoding' },
        { 'fileformat' },
        { 'filetype' },
      },
    },
    tabline = {
      lualine_a = {
        { 'buffers',
          show_modified_status = true,
          show_filename_only = true,
          mode = 0,
          symbols = {
            modified = ' ●', -- Text to show when the buffer is modified
            alternate_file = '', -- Text to show to identify the alternate file
            directory = '', -- Text to show when the buffer is a directory
          },
          filetype_names = {
            NvimTree = 'File Explorer',
            toggleterm = 'Terminal',
            packer = 'Packer',
            lspinfo = 'LSP Info',
            iron = 'REPL',
            tsplayground = 'Playground',
          },
        }
      },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = { 'tabs' }
    }
  }
end

return M
