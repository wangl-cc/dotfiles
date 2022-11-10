local M = {
  after = "tokyonight.nvim", -- wait for colorscheme to load
}

function M.config()
  require("gitsigns").setup {
    current_line_blame_opts = {
      delay = 100,
    },
    diff_opts = {
      internal = true,
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map("n", "]c", function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return "<Ignore>"
      end, { expr = true, desc = "Next change hunk" })
      map("n", "[c", function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return "<Ignore>"
      end, { expr = true, desc = "Previous change hunk" })
      -- Actions
      map(
        { "n", "v" },
        "<leader>hs",
        "<Cmd>Gitsigns stage_hunk<CR>",
        { desc = "Stage hunk" }
      )
      map(
        { "n", "v" },
        "<leader>hr",
        "<Cmd>Gitsigns reset_hunk<CR>",
        { desc = "Reset hunk" }
      )
      map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
      map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
      map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
      map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
      map("n", "<leader>hb", function()
        gs.blame_line { full = true }
      end, { desc = "Blame line" })
      map("n", "<leader>hd", gs.diffthis, { desc = "Diff against the index" })
      map("n", "<leader>hD", function()
        gs.diffthis "~"
      end, { desc = "Diff against the last commit" })
      map(
        "n",
        "<leader>tb",
        gs.toggle_current_line_blame,
        { desc = "Toggle blame of current line" }
      )
      map("n", "<leader>td", gs.toggle_deleted, { desc = "Toggle deleted lines" })
      map("n", "<leader>ts", gs.toggle_signs, { desc = "Toggle git signcolumn" })
      map(
        "n",
        "<leader>tl",
        gs.toggle_linehl,
        { desc = "Toggle git line highlight" }
      )
      map("n", "<leader>tw", gs.toggle_word_diff, { desc = "Toggle word diff" })
    end,
    yadm = {
      enable = true,
    },
  }
end

return M
