local M = {
  opt = true,
  event = {'InsertEnter', 'CmdlineEnter'},
  module = 'cmp',
  requires = {
    { 'hrsh7th/cmp-nvim-lsp', module = 'cmp_nvim_lsp' },
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'dmitmel/cmp-cmdline-history',
    'saadparwaiz1/cmp_luasnip',
    'hrsh7th/cmp-omni',
  },
}

function M.config()
  local cmp = require('cmp')
  local types = require('cmp.types')
  local luasnip = require('luasnip')
  local icons = require('util.icons').icons
  local copilot = require('copilot.suggestion')
  cmp.setup {
    window = {
      completion = {
        col_offset = -1,
        side_padding = 0,
      },
    },
    formatting = {
      fields = { 'kind', 'abbr', 'menu' },
      format = function(_, vim_item)
        vim_item.menu = vim_item.kind
        vim_item.kind = icons[vim_item.kind] or ''
        return vim_item
      end
    },
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert {
      ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4)),
      ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4)),
      ['<C-n>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item({
            behavior = types.cmp.SelectBehavior.Insert
          })
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          cmp.mapping.complete(fallback)
        end
      end),
      ['<C-p>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end),
      -- <Tab> and <S-Tab> are similar to <C-n> and <C-p>
      -- But <Tab> can trigger copilot suggestion while <C-n> not
      -- And <C-n> can trigger complete while <Tab> not
      ['<Tab>'] = cmp.mapping(function(fallback)
        if copilot.is_visible() then
          copilot.accept()
        elseif cmp.visible() then
          cmp.select_next_item({
            behavior = types.cmp.SelectBehavior.Insert
          })
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end),
      ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end),
      ['<CR>'] = cmp.mapping.confirm { select = true },
    },
    -- TODO: source priority
    sources = {
      { name = 'luasnip' },
      { name = 'omni' },
      { name = 'nvim_lsp', max_item_count = 10 },
      { name = 'buffer', max_item_count = 5 },
      { name = 'path', max_item_count = 5 },
    },
  }
  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' },
    },
  })
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'path', max_item_count = 5 },
      { name = 'cmdline', max_item_count = 5 },
      { name = 'cmdline_history', max_item_count = 5 },
    },
  })
end

return M
