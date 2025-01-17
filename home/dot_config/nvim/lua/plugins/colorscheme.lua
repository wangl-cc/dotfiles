---@module 'lazy'
---@type LazyPluginSpec
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  ---@type CatppuccinOptions
  opts = {
    term_colors = true,
    kitty = false, -- Force disable kitty workaround
    background = {
      light = "latte",
      dark = "macchiato",
    },
    default_integrations = false,
    integrations = require("putil.catppuccin").integrations,
    custom_highlights = function(colors)
      local u = require "catppuccin.utils.colors"
      local lualine_bg = colors.mantle
      return {
        -- The default cursor line is not visible enough in the light background
        CursorLine = { bg = u.blend(colors.overlay0, colors.base, 0.3) },
        CursorLineNr = {
          bg = u.blend(colors.overlay0, colors.base, 0.3),
          style = { "bold" },
        },
        LualineGrey = { fg = colors.overlay1, bg = lualine_bg },
        LualineGreen = { fg = colors.green, bg = lualine_bg },
        LualineYellow = { fg = colors.yellow, bg = lualine_bg },
        LualineRed = { fg = colors.red, bg = lualine_bg },
        LualineBlue = { fg = colors.blue, bg = lualine_bg },
      }
    end,
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)

    vim.cmd.colorscheme "catppuccin"
  end,
}
