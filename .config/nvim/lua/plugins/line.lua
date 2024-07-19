-- status line, buffer line and winbar

local tbl = require "util.table"
local icons = require "util.icons"
local import = require "util.import"

local uppercase_filetype = function() return vim.bo.filetype:upper() end
local const_string = function(str)
  return function() return str end
end

local lazy_status = import "lazy.status"
local bd = import("mini.bufremove"):get "delete"

local location = {
  function()
    local cur_line = vim.fn.line "."
    local cur_col = vim.fn.charcol "."
    local total_lines = vim.fn.line "$"
    local progress
    if cur_line == 1 then
      progress = "Top"
    elseif cur_line == total_lines then
      progress = "Bot"
    else
      progress = string.format("%d%%%%", math.floor(cur_line / total_lines * 100))
    end
    return string.format("%d:%d %s", cur_line, cur_col, progress)
  end,
}

local time = {
  function() return os.date "%R" end,
  icon = "",
}

local function with_time(sections)
  sections.lualine_z = { time }
  return sections
end

local function with_time_and_location(sections)
  sections.lualine_y = { location }
  sections.lualine_z = { time }
  return sections
end

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
        {
          sections = with_time {
            lualine_a = {
              function() return "ToggleTerm #" .. vim.b.toggle_number end,
            },
          },
          filetypes = { "toggleterm" },
        },
        {
          sections = with_time {
            lualine_a = {
              function()
                return vim.fn.fnamemodify(vim.uv.cwd() or vim.fn.getcwd(), ":~")
              end,
            },
          },
          filetypes = { "neo-tree" },
        },
        {
          sections = with_time {
            lualine_a = { const_string "TELESCOPE" },
          },
          filetypes = { "TelescopePrompt", "TelescopeResults" },
        },
        {
          sections = with_time {
            lualine_a = { "mode" },
            lualine_b = {
              { "filename", file_status = false },
            },
          },
          filetypes = { "iron" },
        },
        {
          sections = with_time {
            lualine_a = { const_string "LAZY" },
            lualine_b = {
              function()
                local lazy = require "lazy"
                return "Loaded: " .. lazy.stats().loaded .. "/" .. lazy.stats().count
              end,
            },
            lualine_y = {
              {
                lazy_status:get("updates"):with(),
                cond = lazy_status:get("has_updates"):with(),
              },
            },
          },
          filetypes = { "lazy" },
        },
        {
          sections = with_time_and_location {
            lualine_a = { uppercase_filetype },
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
          sections = with_time_and_location {
            lualine_a = { uppercase_filetype },
            lualine_b = { { "filename", file_status = false } },
          },
          filetypes = { "help", "man" },
        },
        {
          sections = with_time_and_location {
            lualine_a = { const_string "TREE" },
          },
          filetypes = { "query" },
        },
      },
      sections = with_time_and_location {
        -- Section A: mode
        lualine_a = { "mode" },
        -- Section B: git status
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
        },
        -- Section C: information of current buffer
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
            icon = "LW:",
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
                  return client.name
                end
              end
              return ""
            end,
            icon = "LS:",
          },
          -- Linter
          {
            function()
              local linters = vim.b.linters
              if not linters or vim.tbl_isempty(linters) then return "" end
              return table.concat(linters, ", ")
            end,
            icon = "LT:",
          },
          -- formatter
          {
            function()
              local ft = vim.bo.filetype
              if ft == "" then return "" end
              local formatters = require("conform").list_formatters()
              local valid_formatters = {}
              for _, formatter in ipairs(formatters) do
                if formatter.available and formatter.name ~= "trim_whitespace" then
                  table.insert(valid_formatters, formatter.name)
                end
              end
              return table.concat(valid_formatters, ", ")
            end,
            icon = "FMT:",
          },
        },
        -- Section X: reserved to show plugin information
        lualine_x = {},
        -- Section Y: location
        -- Section Z: time
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
