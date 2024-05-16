-- status line, buffer line and winbar

local tbl = require "util.table"
local icons = require "util.icons"
local import = require "util.import"

local uppercase_filetype = function() return vim.bo.filetype:upper() end
local const_string = function(str)
  return function() return str end
end

local function capitalize(str) return str:sub(1, 1):upper() .. str:sub(2) end

local normalize = function(str)
  local parts = vim.split(str, "[_-]")
  for i, part in ipairs(parts) do
    parts[i] = capitalize(part)
  end
  return table.concat(parts, " ")
end

local lazy_status = import "lazy.status"
local bd = import("mini.bufremove"):get "delete"

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "UIEnter",
    opts = tbl.merge_options {
      options = {
        theme = "auto",
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      extensions = {
        "neo-tree",
        "quickfix",
        "toggleterm",
        "trouble",
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
            lualine_a = { const_string "LAZY" },
            lualine_b = {
              function()
                local lazy = require "lazy"
                return "Loaded: " .. lazy.stats().loaded .. "/" .. lazy.stats().count
              end,
            },
            lualine_c = {
              {
                lazy_status:get("updates"):with(),
                cond = lazy_status:get("has_updates"):with(),
              },
            },
            lualine_y = { "progress" },
            lualine_z = { "location" },
          },
          filetypes = { "lazy" },
        },
        {
          sections = {
            lualine_a = { uppercase_filetype },
            lualine_y = { "progress" },
            lualine_z = { "location" },
          },
          filetypes = {
            "lspinfo",
            "checkhealth",
            "startuptime",
            "noice",
            "copilot-chat",
            "copilot-diff",
            "copilot-system-prompt",
            "copilot-user-selection",
          },
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
            lualine_a = { const_string "TREE" },
            lualine_y = { "progress" },
            lualine_z = { "location" },
          },
          filetypes = { "query" },
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
            "diagnostics",
            sources = { "nvim_diagnostic" },
            symbols = icons.diagnostic,
          },
        },
        lualine_c = {
          -- Indent method
          {
            function()
              if vim.bo.expandtab then
                return "Spaces: " .. vim.bo.shiftwidth
              else
                return "Tab Size: " .. vim.bo.tabstop
              end
            end,
          },
          -- line width
          {
            function()
              local tw = vim.bo.textwidth
              if tw == 0 then return "" end
              return tw
            end,
            icon = "Line Width:",
          },
          -- file encoding
          {
            function() return vim.bo.fileencoding:upper() end,
          },
          -- file format
          {
            "fileformat",
            symbols = {
              dos = "CRLF",
              unix = "LF",
              mac = "CR",
            },
          },
          -- file type
          {
            "filetype",
            icons_enabled = false,
            fmt = capitalize,
          },
          -- LSP
          {
            function()
              local ft = vim.bo.filetype
              if ft == "" then return "" end
              local clients = vim.lsp.get_clients { bufnr = 0 }
              for _, client in ipairs(clients) do
                ---@diagnostic disable-next-line undefined-field
                local filetypes = client.config.filetypes
                if filetypes and vim.tbl_contains(filetypes, ft) then
                  return normalize(client.name)
                end
              end
              return ""
            end,
            icon = "LS:",
          },
          -- formatter
          {
            function()
              local ft = vim.bo.filetype
              if ft == "" then return "" end
              local formatters = require("conform").list_formatters()
              for _, formatter in ipairs(formatters) do
                if formatter.available and formatter.name ~= "trim_whitespace" then
                  return normalize(formatter.name)
                end
              end
              return ""
            end,
            icon = "FMT:",
          },
        },
        lualine_x = {
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
        },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    -- version = "4",
    event = "UIEnter",
    ---@diagnostic disable: missing-fields
    opts = tbl.merge_options {
      ---@type bufferline.Options
      options = {
        close_command = bd:with("__ARG__", false),
        right_mouse_command = bd:with("__ARG__", false),
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(_, _, diag)
          local dicons = icons.diagnostic
          local ret = (diag.error and dicons.error .. diag.error .. " " or "")
            .. (diag.warning and dicons.warn .. diag.warning or "")
          return vim.trim(ret)
        end,
        separator_style = "slant",
        indicator = { style = "underline" },
        hover = {
          enabled = true,
          delay = 200,
          reveal = { "close" },
        },
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            highlight = "Directory",
            text_align = "center",
          },
        },
      },
    },
    ---@diagnostic enable: missing-fields
    ---@param opts bufferline.UserConfig
    config = function(_, opts)
      local bufferline = require "bufferline"
      bufferline.groups.builtin.pinned.icon = ""
      opts.highlights = require("catppuccin.groups.integrations.bufferline").get()
      bufferline.setup(opts)
    end,
  },
  {
    "utilyre/barbecue.nvim",
    version = "1",
    event = "UIEnter",
    dependencies = {
      "SmiteshP/nvim-navic",
    },
    opts = {
      attach_navic = false,
      -- HACK: the file type `""` will disable all buffer without a file type.
      -- This is needed for Trouble to work properly,
      -- because its filetype is set a bit late.
      exclude_filetypes = {
        "neo-tree",
        "iron",
        "Trouble",
        "toggleterm",
        "copilot-chat",
        "copilot-diff",
        "copilot-system-prompt",
        "copilot-user-selection",
        "",
      },
      kinds = require("util.icons").kinds,
    },
  },
}
