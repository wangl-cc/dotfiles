local import = require "util.import"
local register = require "util.keymap"

local builtins = import "telescope.builtin"

---@param buffer number
return function(buffer)
  ---@type KeymapTree
  local maps = {
    g = {
      ---@type KeymapOption
      d = {
        callback = builtins:get("lsp_definitions"):with { jump_type = "never" },
        desc = "Go to definition",
      },
      ---@type KeymapOption
      D = {
        callback = builtins:get("lsp_definitions"):with { jump_type = "never" },
        desc = "Go to type definitions",
      },
      ---@type KeymapOption
      r = {
        callback = builtins:get("lsp_references"):with { jump_type = "never" },
        desc = "Go to references",
      },
      R = {
        callback = import("trouble"):get("open"):with { mode = "lsp_references" },
        desc = "List references",
      },
      ---@type KeymapOption
      i = {
        callback = builtins:get("lsp_implementations"):with { jump_type = "never" },
        desc = "Go to implementations",
      },
    },
    ---@type KeymapTree
    ["<leader>"] = {
      ---@type KeymapOption
      ["."] = { callback = vim.lsp.buf.code_action, desc = "Show code actions" },
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
