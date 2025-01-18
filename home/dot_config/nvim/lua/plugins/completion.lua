require("putil.catppuccin").add_integrations { blink_cmp = true }

return {
  "saghen/blink.cmp",
  version = "*",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    { "rafamadriz/friendly-snippets" },
  },

  opts_extend = {
    "sources.completion.enabled_providers",
    "sources.compat",
    "sources.default",
  },

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = "default",
      ["<Enter>"] = { "accept", "fallback" },
      ["<Tab>"] = { "snippet_forward", "fallback" },
      ["<S-Tab>"] = { "snippet_backward", "fallback" },

      cmdline = {
        preset = "default",
        ["<Tab>"] = { "select_and_accept", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
      },
    },
    completion = {
      menu = {
        winblend = vim.o.winblend,
        scrollbar = false,
      },
      accept = { auto_brackets = { enabled = true } },
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      per_filetype = {
        codecompanion = { "codecompanion" },
      },
    },
  },
}
