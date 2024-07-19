local tbl = LDU.tbl

return {
  ---@type LazyPluginSpec
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    opts = tbl.merge_options {
      flavour = "auto",
      background = {
        light = "latte",
        dark = "macchiato",
      },
      kitty = false, -- force no kitty workaround
      transparent_background = true,
      default_integrations = false,
      ---@type CtpIntegrations
      integrations = {
        cmp = true,
        neotree = true,
        window_picker = true,
        indent_blankline = {
          enabled = true,
          scope_color = "sapphire",
          colored_indent_levels = false,
        },
        gitsigns = true,
        telescope = { enabled = true },
        barbecue = {
          dim_dirname = true,
          bold_basename = true,
          dim_context = false,
          alt_background = false,
        },
        notify = true,
        noice = true,
        treesitter = true,
        treesitter_context = true,
        rainbow_delimiters = true,
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
          },
          inlay_hints = {
            background = true,
          },
        },
        lsp_trouble = true,
        semantic_tokens = true,
        which_key = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme "catppuccin"
    end,
  },
}
