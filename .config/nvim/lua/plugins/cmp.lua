local M = {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "saadparwaiz1/cmp_luasnip",
    { --- Snippets
      "L3MON4D3/LuaSnip",
      build = "make install_jsregexp",
      config = function() require("luasnip/loaders/from_vscode").lazy_load() end,
    },
  },
}

function M.config()
  local cmp = require "cmp"
  local luasnip = require "luasnip"
  local copilot = require "copilot.suggestion"

  local feedkeys = require "cmp.utils.feedkeys"
  local keymap = require "cmp.utils.keymap"

  local icons = require("util.icons").completion

  local source_names = {
    nvim_lsp = "LSP",
    cmdline_path = "path",
  }
  local function buf_get_char(buffer, row, col)
    row = row - 1
    return vim.api.nvim_buf_get_text(buffer, row, col - 1, row, col, {})[1]
  end

  local function has_words_before()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and buf_get_char(0, row, col):match "%s" == nil
  end

  cmp.setup {
    window = {
      completion = {
        winhighlight = "Normal:Normal,FloatBorder:Normal,Search:None",
        col_offset = -1,
        side_padding = 0,
      },
      documentation = {
        border = "rounded",
        winhighlight = "Normal:Normal,FloatBorder:Normal,Search:None",
      },
    },
    formatting = {
      fields = { "kind", "abbr", "menu" },
      format = function(entry, vim_item)
        local name = entry.source.name
        vim_item.kind = icons[vim_item.kind] or ""
        vim_item.menu = ("[%s]"):format(source_names[name] or name)
        return vim_item
      end,
    },
    snippet = {
      expand = function(args) luasnip.lsp_expand(args.body) end,
    },
    mapping = cmp.mapping.preset.insert {
      ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4)),
      ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4)),
      ["<C-n>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end),
      ["<C-p>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end),
      -- <Tab> and <S-Tab> to accept copilot suggestionActions
      -- or complete common string when copilot is not visible
      ["<Tab>"] = cmp.mapping(function(fallback)
        if copilot.is_visible() then
          copilot.accept()
        elseif cmp.visible() then
          cmp.complete_common_string()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if copilot.is_visible() then
          copilot.dismiss()
        elseif cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end),
      ["<CR>"] = cmp.mapping.confirm { select = true },
    },
    -- TODO: source priority
    sources = {
      { name = "nvim_lsp", max_item_count = 15 },
      { name = "luasnip", max_item_count = 5 },
      { name = "buffer", max_item_count = 5 },
      { name = "path", max_item_count = 5 },
    },
  }
  local cmdline_mappings = cmp.mapping.preset.cmdline {
    ["<Tab>"] = {
      c = function()
        if cmp.visible() then
          cmp.complete_common_string()
        else
          feedkeys.call(keymap.t "<C-z>", "n")
        end
      end,
    },
  }
  cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmdline_mappings,
    sources = {
      { name = "buffer" },
    },
  })
  --HACK:we warp the complete of the cmp_path source to escape `#` in path
  local cmdline_path = require("cmp_path").new()
  local complete = cmdline_path.complete
  ---@diagnostic disable-next-line: duplicate-set-field
  cmdline_path.complete = function(self, params, callback)
    local callback_new = function(candidates)
      if not candidates then
        callback()
        return
      end
      for _, candidate in ipairs(candidates) do
        candidate.label = candidate.label:gsub("#", "\\#")
        candidate.insertText = candidate.insertText:gsub("#", "\\#")
        local word = candidate.word
        if word then candidate.word = word:gsub("#", "\\#") end
      end
      callback(candidates)
    end
    return complete(self, params, callback_new)
  end
  cmp.register_source("cmdline_path", cmdline_path)
  cmp.setup.cmdline(":", {
    mapping = cmdline_mappings,
    sources = {
      {
        name = "cmdline_path",
        max_item_count = 5,
        group_index = 1,
      },
      {
        name = "cmdline",
        max_item_count = 20,
        group_index = 2,
      },
    },
  })
end

return M
