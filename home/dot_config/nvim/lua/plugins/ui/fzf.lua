local lualine = require "putil.lualine"

lualine.registry_extension(
  "fzf",
  lualine.util.with_time {
    lualine_a = {
      lualine.util.const_string "FZF",
    },
  }
)

require("putil.catppuccin").add_integrations { fzf = true }

local fzf = Util.import "fzf-lua"

---@type table<string, KeymapSpec>
local find_keymaps = {
  [""] = { "", desc = "search" },
  f = { fzf:get("files"):closure(), desc = "Search files" },
  b = { fzf:get("buffers"):closure(), desc = "Search buffers" },
  w = { fzf:get("live_grep"):closure(), desc = "Search words in CWD" },
  p = {
    callback = function()
      local parsers = require "nvim-treesitter.parsers"
      local parser_list = parsers.available_parsers()
      table.sort(parser_list)
      local parser_info = {}
      for _, lang in ipairs(parser_list) do
        table.insert(parser_info, {
          lang = lang,
          status = parsers.has_parser(lang),
        })
      end
      vim.ui.select(parser_info, {
        prompt = "Update parser",
        format_item = function(item)
          -- use + to search installed parser and - search uninstalled parser
          return string.format("%s %s", item.status and "+" or "-", item.lang)
        end,
      }, function(selected)
        if selected then
          require("nvim-treesitter.install").update()(selected.lang)
        end
      end)
    end,
    desc = "Search a tree-sitter parser to update",
  },
}

local git_keymaps = {
  l = { fzf:get("git_commits"):closure(), desc = "Search git commits" },
  f = {
    fzf:get("git_bcommits"):closure(),
    desc = "Search git commits for current file",
  },
  s = { fzf:get("git_status"):closure(), desc = "Search git status" },
  b = { fzf:get("git_branches"):closure(), desc = "Search git branches" },
}

Util.register({
  [" "] = {
    fzf:get("builtin"):closure(),
    desc = "Search fzf builtins",
  },
  [";"] = {
    fzf:get("command_history"):closure(),
    desc = "Search command history",
  },
  s = find_keymaps,
  g = git_keymaps,
}, { prefix = "<leader>" })

return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  opts = {
    file_icon_padding = " ",
    fzf_colors = true,
    keymap = {
      builtin = {
        ["<M-Esc>"] = "hide",
        ["<C-f>"] = "preview-page-down",
        ["<C-b>"] = "preview-page-up",
      },
    },
  },
  config = function(_, opts)
    local config = require "fzf-lua.config"
    local ok, trouble = pcall(require, "trouble.sources.fzf")
    if ok then config.defaults.actions.files["ctrl-t"] = trouble.actions.open_all end

    require("fzf-lua").setup(opts)

    require("fzf-lua.providers.ui_select").register()
  end,
}
