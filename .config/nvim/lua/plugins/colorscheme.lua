local tbl = require "util.table"

return {
  ---@type LazyPluginSpec
  {
    "folke/tokyonight.nvim",
    version = "3",
    event = "UIEnter",
    opts = tbl.merge_options {
      style = "moon",
      styles = {
        floats = "transparent",
      },
      sidebars = { "qf" },
      on_highlights = function(hls, c)
        local function base_on(base, opts)
          local hl = hls[base]
          if not hl then
            require("util.log").error(
              "Highlight group not found: " .. base,
              "Highlight"
            )
          end
          -- vim.tbl_extend will create new table, so it's safe to modify it.
          return vim.tbl_extend("force", hl, opts)
        end

        -- highlight for indentmini
        hls.IndentLine = { fg = c.fg_gutter, nocombine = true }

        -- highlight for window-picker
        hls.WindowPickerStatusLine = { fg = c.black, bg = c.blue }
        hls.WindowPickerStatusLineNC = { fg = c.black, bg = c.blue }
        hls.WindowPickerWinBar = { fg = c.black, bg = c.blue }
        hls.WindowPickerWinBarNC = { fg = c.black, bg = c.blue }

        -- highlight for treesitter
        hls["@keyword"].fg = c.magenta2 -- The original color is purple, which is not very obvious in the light theme
        hls["@keyword.function"] = hls["@keyword"] -- e.g. `function`, `end` in Julia
        hls["@keyword.operator"] = base_on("@operator", { style = "italic" }) -- e.g. `in`, `isa` in Julia, `and`, `or` in Lua
        hls["Conditional"] = base_on("Statement", { style = "italic" }) -- e.g. `if`, `else`, `elseif`, `end` in Julia
        hls["Repeat"] = base_on("Statement", { style = "italic" }) -- e.g. `for`, `while`, `end` in Julia
        hls["Include"] = base_on("Statement", { style = "italic" }) -- e.g. `using`, `import` in Julia
        hls["Exception"] = base_on("Statement", { style = "italic" }) -- e.g. `try`, `catch`, `finally` in Julia
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme "tokyonight"
      vim.cmd.doautocmd { args = { "User", "ColorSchemeLoaded" } }
    end,
  },
}
