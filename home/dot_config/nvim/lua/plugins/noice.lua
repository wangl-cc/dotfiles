require("putil.catppuccin").add_integrations { noice = true }

return {
  "folke/noice.nvim",
  -- FIXME: Temporary disable version, there is a fix not yet released
  -- version = "*",
  event = "UIEnter",
  opts = {
    cmdline = {
      format = {
        substitute = {
          -- a space before % to avoid this for normal sub
          pattern = [[: %%s/[\<>_%a]+/]],
          icon = "",
          opts = {
            relative = "cursor",
            size = { min_width = 20 },
            position = { row = 2, col = -2 },
          },
        },
        filter = {
          kind = "shell",
          lang = vim.fs.basename(vim.o.shell) == "fish" and "fish" or "bash",
        },
      },
    },
    presets = {
      bottom_search = true,
      long_message_to_split = true,
      inc_rename = true,
      lsp_doc_border = false,
    },
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
      },
    },
    views = {
      cmdline_popup = {
        position = {
          row = "20%",
          col = "50%",
        },
      },
      confirm = {
        position = {
          row = "80%",
          col = "50%",
        },
      },
    },
  },
}
