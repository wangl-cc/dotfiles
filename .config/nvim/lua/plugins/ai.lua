local tbl = require "util.table"

local capitalize = require("util.string").capitalize

local cached_colors = {
  theme = nil,
  bg = nil,
  colors = {},
}

setmetatable(cached_colors, {
  __index = function(cache, name)
    -- If color scheme or background has changed, clear the cache
    local theme = vim.g.colors_name
    local bg = vim.o.background
    if rawget(cache, "theme") ~= theme or rawget(cache, "bg") ~= bg then
      cache.theme = theme
      cache.bg = bg
      cache.colors = {}
    end

    local color = cache.colors[name]
    if not color then
      color = require("util.color").fg(name)
      if not color then return {} end
      cache.colors[name] = color
    end

    return { fg = color }
  end,
})

local status_color = {
  Normal = "DiagnosticOk",
  [""] = "DiagnosticInfo",
  InProgress = "DiagnosticWarn",
  Warning = "DiagnosticError",
}

return {
  ---@type LazyPluginSpec
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      {
        "nvim-lualine/lualine.nvim",
        optional = true,
        opts = tbl.merge_options {
          sections = {
            lualine_x = {
              {
                function()
                  return " " .. require("copilot.api").status.data.message
                end,
                cond = function()
                  if not package.loaded.copilot then return false end
                  local ok, clients =
                    pcall(vim.lsp.get_clients, { name = "copilot", bufnr = 0 })
                  return ok and #clients > 0
                end,
                color = function()
                  local status = require("copilot.api").status.data.status or ""
                  return cached_colors[status_color[status]]
                end,
                on_click = function()
                  local status = require("copilot.api").status.data
                  if status.status == "Warning" then
                    vim.notify(
                      status.message,
                      vim.log.levels.WARN,
                      { title = "Copilot" }
                    )
                  elseif status.status == "Normal" then
                    vim.notify(
                      "Everything went well!",
                      vim.log.levels.INFO,
                      { title = "Copilot" }
                    )
                  elseif status.status == "InProgress" then
                    vim.notify(
                      "Waiting for suggestions...",
                      vim.log.levels.INFO,
                      { title = "Copilot" }
                    )
                  elseif #status.message > 0 then
                    vim.notify(
                      status.message,
                      vim.log.levels.INFO,
                      { title = "Copilot" }
                    )
                  end
                end,
              },
            },
          },
        },
      },
    },
    cmd = "Copilot",
    opts = tbl.merge_options {
      filetypes = {
        help = false,
        iron = false,
        toggleterm = false,
        ["*"] = true,
      },
      panel = {
        enabled = false,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
      },
    },
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    version = "2",
    cmd = { "CopilotChat" },
    dependencies = "zbirenbaum/copilot.lua",
    opts = {
      question_header = "  " .. (capitalize(vim.env.USER) or "User") .. " ",
      answer_header = "  Copilot ",
      error_header = "  Error ",
      auto_insert_mode = true,
      show_help = false,
      history_path = vim.fn.stdpath "state" .. "/copilot_chat_history",
    },
  },
}
