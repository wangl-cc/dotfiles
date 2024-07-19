local import = LDU.import
local register = LDU.register

local builtins = import "telescope.builtin"
local trouble_open = import("trouble"):get "open"

---@param buffer number
return function(buffer)
  ---@type KeymapTree
  local maps = {
    g = {
      ---@type KeymapOption
      d = {
        callback = trouble_open:with { mode = "lsp_definitions" },
        desc = "Go to definition",
      },
      ---@type KeymapOption
      D = {
        callback = trouble_open:with { mode = "lsp_type_definitions" },
        desc = "Go to type definitions",
      },
      ---@type KeymapOption
      r = {
        callback = trouble_open:with { mode = "lsp_references" },
        desc = "Go to references",
      },
    },
    ---@type KeymapTree
    ["<leader>"] = {
      ---@type KeymapOption
      ["."] = { callback = vim.lsp.buf.code_action, desc = "Show code actions" },
      ---@type KeymapOption
      ["k"] = {
        callback = vim.lsp.buf.hover,
        desc = "Show hover information",
      },
      ---@type KeymapTree
      s = {
        ---@type KeymapOption
        d = {
          callback = builtins:get("diagnostics"):with { bufnr = 0 },
          desc = "Search all diagnostics if current buffer",
        },
        ---@type KeymapOption
        s = {
          callback = builtins:get("lsp_document_symbols"):with(),
          desc = "Search all symbols in current buffer",
        },
      },
      ---@type KeymapTree
      w = {
        ---@type KeymapOption
        a = {
          callback = function()
            vim.ui.input({
              prompt = "Workspace folder to be added",
              default = vim.fn.expand "%:p:h",
            }, function(dir)
              if dir then vim.lsp.buf.add_workspace_folder(dir) end
            end)
          end,
          desc = "Add workspace folder",
        },
        ---@type KeymapOption
        d = {
          function()
            vim.ui.select(vim.lsp.buf.list_workspace_folders(), {
              prompt = "Workspace folder to be removed",
            }, function(dir)
              if dir then vim.lsp.buf.remove_workspace_folder(dir) end
            end)
          end,
          desc = "Remove workspace folder",
        },
      },
      ---@type KeymapOption
      cn = {
        callback = function() return ":IncRename " .. vim.fn.expand "<cword>" end,
        expr = true,
        desc = "Rename all references of symbol under the cursor",
      },
    },
  }

  register(maps, { buffer = buffer, silent = true })
end
