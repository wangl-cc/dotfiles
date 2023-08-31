local tbl = require "util.table"
local import = require "util.import"
local register = require "util.keymap"

local builtins = import "telescope.builtin"

---@param buffer number
return function(buffer)
  ---@param builtin string
  ---@param opts? table
  local function telescope(builtin, opts)
    opts = tbl.merge_one({
      bufnr = buffer,
      jump_type = "never",
      layout_config = {
        height = 12,
      },
    }, opts)
    return function()
      opts = require("telescope.themes").get_cursor(opts)
      require("telescope.builtin")[builtin](opts)
    end
  end

  ---@type KeymapTree
  local maps = {
    g = {
      ---@type KeymapOption
      d = {
        callback = telescope "lsp_definitions",
        desc = "Go to definition",
      },
      ---@type KeymapOption
      D = {
        callback = telescope "lsp_type_definitions",
        desc = "Go to type definitions",
      },
      ---@type KeymapOption
      r = {
        callback = telescope "lsp_references",
        desc = "Go to references",
      },
      R = {
        callback = import("trouble"):get("open"):with { mode = "lsp_references" },
        desc = "List references",
      },
      ---@type KeymapOption
      i = {
        callback = telescope "lsp_implementations",
        desc = "Go to implementations",
      },
    },
    ---@type KeymapTree
    ["<leader>"] = {
      ---@type KeymapOption
      k = { callback = vim.lsp.buf.hover, desc = "Show hover and signature help" },
      ---@type KeymapOption
      K = { callback = vim.lsp.buf.signature_help, desc = "Show signature help" },
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
