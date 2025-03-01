require("putil.catppuccin").add_integrations { gitsigns = true }

return {
  "lewis6991/gitsigns.nvim",
  event = "UIEnter",
  opts = Util.tbl.merge_options {
    numhl = true,
    current_line_blame_opts = {
      delay = 100,
    },
    diff_opts = {
      internal = true,
    },
    on_attach = function(buffer)
      local gs = package.loaded.gitsigns
      -- Navigation
      Util.register({
        ["]"] = {
          callback = function()
            if vim.wo.diff then return "]c" end
            vim.schedule(function() gs.next_hunk() end)
            return "<Ignore>"
          end,
          expr = true,
          desc = "Next change hunk",
        },
        ["["] = {
          callback = function()
            if vim.wo.diff then return "[c" end
            vim.schedule(function() gs.prev_hunk() end)
            return "<Ignore>"
          end,
          expr = true,
          desc = "Previous change hunk",
        },
      }, { suffix = "c", buffer = buffer })

      -- Actions
      Util.register({
        h = {
          [""] = { "", desc = "git hunk" },
          s = {
            [[<Cmd>Gitsigns stage_hunk<CR>]],
            mode = { "n", "v" },
            desc = "Stage hunk",
          },
          S = { callback = gs.stage_buffer, desc = "Stage buffer" },
          r = {
            [[<Cmd>Gitsigns reset_hunk<CR>]],
            mode = { "n", "v" },
            desc = "Reset hunk",
          },
          R = { callback = gs.reset_buffer, desc = "Reset buffer" },
          u = { callback = gs.undo_stage_hunk, desc = "Undo stage hunk" },
          p = { callback = gs.preview_hunk, desc = "Preview hunk" },
          b = { callback = gs.blame_line, desc = "Blame line" },
          d = { callback = gs.diffthis, desc = "Diff this hunk" },
          D = {
            callback = function() gs.diffthis "~" end,
            desc = "Diff against the last commit",
          },
        },
        t = {
          b = {
            callback = gs.toggle_current_line_blame,
            desc = "Toggle current line blame",
          },
          d = { callback = gs.toggle_deleted, desc = "Toggle deleted lines" },
          s = { callback = gs.toggle_signs, desc = "Toggle git sign column" },
          l = { callback = gs.toggle_linehl, desc = "Toggle line highlight" },
          w = { callback = gs.toggle_word_diff, desc = "Toggle word diff" },
          n = { callback = gs.toggle_numhl, desc = "Toggle number highlight" },
        },
      }, { prefix = "<leader>", buffer = buffer })
    end,
  },
}
