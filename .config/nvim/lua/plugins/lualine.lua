local M = {
  "nvim-lualine/lualine.nvim",
  event = "UIEnter",
}

function M.config()
  local uppercase_filetype = function() return vim.bo.filetype:upper() end
  local const_string = function(str)
    return function() return str end
  end
  local noice = require("noice").api.status
  local icons = require "util.icons"
  require("lualine").setup {
    options = {
      theme = "tokyonight",
      globalstatus = true,
      component_separators = { left = "", right = "│" },
      section_separators = { left = "", right = "" },
    },
    extensions = {
      "neo-tree",
      "quickfix",
      "toggleterm",
      {
        sections = {
          lualine_a = { const_string "TELESCOPE" },
        },
        filetypes = { "TelescopePrompt", "TelescopeResults" },
      },
      {
        sections = {
          lualine_a = { "mode" },
          lualine_b = {
            { "filename", file_status = false },
          },
        },
        filetypes = { "iron" },
      },
      {
        sections = {
          lualine_a = { uppercase_filetype },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        filetypes = { "lspinfo", "checkhealth", "startuptime", "lazy" },
      },
      {
        sections = {
          lualine_a = { uppercase_filetype },
          lualine_b = { { "filename", file_status = false } },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        filetypes = { "help", "man" },
      },
      {
        sections = {
          lualine_a = { const_string "PLAYGROUND" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        filetypes = { "tsplayground" },
      },
    },
    sections = {
      lualine_a = {
        { "mode", icons_enabled = true },
      },
      lualine_b = {
        {
          "branch",
          icons_enabled = true,
          icon = "",
        },
        {
          "diff",
          symbols = icons.diff,
          source = function()
            ---@diagnostic disable-next-line undefined-field
            local gs_st = vim.b.gitsigns_status_dict
            return gs_st
              and {
                added = gs_st.added,
                modified = gs_st.changed,
                removed = gs_st.removed,
              }
          end,
        },
        {
          "filename",
          file_status = true,
          symbols = icons.file_status,
        },
      },
      lualine_c = {
        {
          "diagnostics",
          sources = { "nvim_lsp" },
          symbols = icons.diagnostic,
        },
      },
      lualine_x = {
        {
          noice.hunk.get,
          cond = noice.hunk.has,
        },
        {
          function()
            if vim.v.hlsearch == 0 then return "" end
            local result = vim.fn.searchcount { timeout = 500, maxcount = 99 }
            if result.total == 0 or result.current == 0 then return "" end
            local str
            if result.incomplete == 1 then
              str = "/%s [?/?]"
            elseif result.incomplete == 2 then
              if result.current > result.maxcount then
                str = "/%s [>%d/>%d]"
              else
                str = "/%s [%d/>%d]"
              end
            else
              str = "/%s [%d/%d]"
            end
            local pattern = vim.fn.getreg("/"):gsub("%%", "%%%%")
            return str:format(pattern, result.current, result.total)
          end,
        },
        { "encoding" },
        { "fileformat" },
        { "filetype" },
      },
    },
    tabline = {
      lualine_a = {
        {
          "buffers",
          show_modified_status = true,
          show_filename_only = true,
          mode = 0,
          symbols = { alternate_file = "" },
          filetype_names = {
            ["neo-tree"] = "File Explorer",
            checkhealth = "Check Health",
            toggleterm = "Terminal",
            packer = "Packer",
            lspinfo = "LSP Info",
            iron = "REPL",
            tsplayground = "Playground",
            startuptime = "Startup Time",
            lazy = "Plugin Manager",
          },
        },
      },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = { { "tabs", mode = 1 } },
    },
  }
end

return M
