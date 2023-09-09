local tbl = require "util.table"

local function hl_override(hl, name, opts)
  local g = hl[name]
  if g and not g.link then
    for k, v in pairs(opts) do
      g[k] = v
    end
  else -- if g is not defined or g link to other group
    if not g then g = vim.api.nvim_get_hl(0, { name = name }) end
    while g.link do
      -- get link of g from hl or from vim
      g = hl[g.link] or vim.api.nvim_get_hl(0, { name = g.link })
    end
    local g2 = vim.deepcopy(g)
    for k, v in pairs(opts) do
      g2[k] = v
    end
    hl[name] = g2
  end
end

return {
  ---@type LazyPluginSpec
  {
    "wangl-cc/auto-bg.nvim",
    event = "UIEnter",
    build = "make",
    opts = {},
  },
  ---@type LazyPluginSpec
  {
    "folke/tokyonight.nvim",
    version = "2",
    lazy = false,
    priority = 1000,
    opts = tbl.merge_options {
      style = "moon",
      styles = {
        floats = "transparent",
      },
      sidebars = { "qf" },
      on_highlights = function(hl, c)
        hl.WindowPickerStatusLine = { fg = c.black, bg = c.blue }
        hl.WindowPickerStatusLineNC = { fg = c.black, bg = c.blue }
        hl.WindowPickerWinBar = { fg = c.black, bg = c.blue }
        hl.WindowPickerWinBarNC = { fg = c.black, bg = c.blue }
        hl_override(hl, "@keyword.function", { style = "italic" }) -- e.g. `function`, `end` in Julia
        hl_override(hl, "@keyword.operator", { style = "italic" }) -- e.g. `in`, `isa` in Julia, `and`, `or` in Lua
        hl_override(hl, "Conditional", { style = "italic" }) -- e.g. `if`, `else`, `elseif`, `end` in Julia
        hl_override(hl, "Repeat", { style = "italic" }) -- e.g. `for`, `while`, `end` in Julia
        hl_override(hl, "Include", { style = "italic" }) -- e.g. `using`, `import` in Julia
        hl_override(hl, "Exception", { style = "italic" }) -- e.g. `try`, `catch`, `finally` in Julia
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme "tokyonight"
    end,
  },
}
