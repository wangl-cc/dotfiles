local util = require "util.reload"
local lspconfig = require "lspconfig"
local cmp_lsp = require "cmp_nvim_lsp"
local tbl = require "util.table"
local register = require("util.keymap").register
local import = require "util.import"

local M = {}

local make_capabilities = cmp_lsp.default_capabilities

local format_group = vim.api.nvim_create_augroup("AutoFormat", { clear = true })
M.autoformat = {} ---@type boolean[]
setmetatable(M.autoformat, {
  __index = function(_, buffer)
    if buffer == 0 then buffer = vim.api.nvim_get_current_buf() end
    return rawget(M.autoformat, buffer)
  end,
  __newindex = function(_, buffer, value)
    if type(value) == "boolean" then
      rawset(M.autoformat, buffer, value)
    else -- nil
      rawset(M.autoformat, buffer, M.options.autoformat)
    end
  end,
})

local function on_attach_common(client, buffer)
  -- Keymaps
  ---@type KeymapTree
  local mappings = {
    ---@type KeymapTree
    g = {
      ---@type KeymapOption
      d = { [[<Cmd>Telescope lsp_definitions<CR>]], desc = "Go to definition" },
      ---@type KeymapOption
      D = {
        [[<Cmd>Telescope lsp_type_definitions<CR>]],
        desc = "Go to type definitions",
      },
      ---@type KeymapOption
      r = { [[<Cmd>Telescope lsp_references<CR>]], desc = "Go to references" },
      R = {
        import("trouble")["open"] { mode = "lsp_references" },
        desc = "List references",
      },
      ---@type KeymapOption
      i = {
        [[<Cmd>Telescope lsp_implementations<CR>]],
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
          [[<Cmd>Telescope diagnostics bufnr=0<CR>]],
          desc = "Search all diagnostics if current buffer",
        },
        ---@type KeymapOption
        s = {
          [[<Cmd>Telescope lsp_document_symbols<CR>]],
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

  -- Format
  -- Enable formatting if the client supports it or if null-ls is available
  local ft = vim.bo[buffer].filetype
  local have_nls = #require("null-ls.sources").get_available(
      ft,
      "NULL_LS_FORMATTING"
    ) > 0
  if client.supports_method "textDocument/formatting" or have_nls then
    local leader = mappings["<leader>"]
    local server_opts = M.options.servers[client.name]
    if server_opts then M.autoformat[buffer] = server_opts.autoformat end
    local format = function(opts)
      local options = {
        async = true,
        bufnr = buffer,
        filter = function(c)
          if have_nls then return c.name == "null-ls" end
          return c.name ~= "null-ls"
        end,
      }
      tbl.merge_one(options, opts)
      vim.lsp.buf.format(options)
    end
    ---@type KeymapOption
    leader.f = { callback = format, desc = "Format" }

    -- Autoformat
    vim.api.nvim_clear_autocmds {
      group = format_group,
      buffer = buffer,
    }
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = format_group,
      buffer = buffer,
      callback = function()
        if M.autoformat[buffer] then format { async = false } end
      end,
    })
    ---@type KeymapOption
    leader.tf = {
      callback = function()
        if M.autoformat[buffer] ~= nil then
          M.autoformat[buffer] = not M.autoformat[buffer]
          vim.notify(
            M.autoformat[buffer] and "Enabled format on save"
              or "Disabled format on save",
            vim.log.levels.INFO,
            { title = "Autoformat" }
          )
        end
      end,
      desc = "Toggle autoformat",
    }
  end

  -- Register mappings
  register(mappings, { buffer = buffer, silent = true })

  -- Attach nvim-navic to LSP clients
  if client.server_capabilities.documentSymbolProvider then
    local ok, navic = pcall(require, "nvim-navic")
    if ok then navic.attach(client, buffer) end
  end
end

---@class LspConfig
---@field disabled? boolean Whether to disable this lsp
---@field autoformat? boolean Whether to enable autoformat
---@field setup_capabilities? fun(capabilities:table):table Setup capabilities
---@field options? table Options to be passed to lspconfig

---@param opts LspConfig|string Config for lspconfig, if string it is treated as a lua module name
---@param reload? boolean Whether to reload the module
---@return LspConfig opts Processed lspconfig
local function process_config(opts, reload)
  if type(opts) == "string" then
    if reload then
      return util.reload(opts)
    else
      return require(opts)
    end
  else -- LspConfig
    return opts
  end
end

---@param server string
---@param config LspConfig
local function setup_server(server, config)
  -- don't setup if server is disabled
  if config.disabled then return end
  local options = config.options or {}
  local function on_attach(client, bufnr)
    on_attach_common(client, bufnr)
    if options.on_attach then options.on_attach(client, bufnr) end
  end

  local capabilities = make_capabilities()
  if config.setup_capabilities then config.setup_capabilities(capabilities) end
  local new_options = vim.deepcopy(options)
  new_options.on_attach = on_attach
  new_options.capabilities = capabilities
  return lspconfig[server].setup(new_options)
end

---@class LspSetupOptions
---@field autoformat? boolean Whether to autoformat on save
---@field servers? table<string, LspConfig|string> List of servers to be setup

---@type LspSetupOptions
M.options = {
  autoformat = true,
  servers = {},
}

---@param opts LspSetupOptions
M.setup = function(opts)
  tbl.merge_one(M.options, opts)
  register({
    ["]"] = {
      callback = vim.diagnostic.goto_next,
      desc = "Go to next diagnostic",
    },
    ["["] = {
      callback = vim.diagnostic.goto_prev,
      desc = "Go to previous diagnostic",
    },
  }, { suffix = "d" })
  local icons = require("util.icons").diagnostic
  for name, icon in pairs(icons) do
    name = "DiagnosticSign" .. name:sub(1, 1):upper() .. name:sub(2)
    vim.fn.sign_define(name, { text = icon, texthl = name, numhl = name })
  end
  for server, config in pairs(M.options.servers) do
    setup_server(server, process_config(config))
  end
end

return M

-- vim:tw=76:ts=2:sw=2:et
