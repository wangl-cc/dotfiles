local trouble_open = Util.import("trouble"):get "open"

---@param buffer integer
return function(buffer)
  ---@type KeymapTree
  local maps = {
    g = {
      ---@type KeymapOption
      d = {
        callback = trouble_open:closure { mode = "lsp_definitions" },
        desc = "Go to definition",
      },
      ---@type KeymapOption
      D = {
        callback = trouble_open:closure { mode = "lsp_type_definitions" },
        desc = "Go to type definitions",
      },
      ---@type KeymapOption
      r = {
        callback = trouble_open:closure { mode = "lsp_references" },
        desc = "Go to references",
      },
    },
    ---@type KeymapTree
    ["<leader>"] = {
      ---@type KeymapOption
      ["."] = {
        callback = function() require("fzf-lua").lsp_code_actions() end,
        desc = "Show code actions",
      },
      ---@type KeymapOption
      --@type KeymapOption
      ["th"] = {
        callback = function()
          local inlay_hint = vim.lsp.inlay_hint
          local filter = { bufnr = buffer }
          if inlay_hint.is_enabled(filter) then
            inlay_hint.enable(false, filter)
          else
            inlay_hint.enable(true, filter)
          end
        end,
        desc = "Toggle inlay hints",
      },
      ---@type KeymapOption
      cd = {
        callback = function() return ":IncRename " .. vim.fn.expand "<cword>" end,
        expr = true,
        desc = "Rename all references of symbol under the cursor",
      },
    },
  }

  Util.register(maps, { buffer = buffer, silent = true })
end
