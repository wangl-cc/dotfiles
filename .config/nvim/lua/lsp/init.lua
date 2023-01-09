local util = require "util.reload"
local lspconfig = require "lspconfig"
local cmp_lsp = require "cmp_nvim_lsp"

local M = {}

local make_capabilities = cmp_lsp.default_capabilities

local function keymap(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.noremap = vim.F.if_nil(opts.noremap, true)
  opts.silent = vim.F.if_nil(opts.silent, true)
  vim.keymap.set(mode, lhs, rhs, opts)
end

local format_group = vim.api.nvim_create_augroup("AutoFormat", { clear = true })

local on_attach_common = function(client, bufnr)
  local function buf_keymap(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.buffer = bufnr
    keymap(mode, lhs, rhs, opts)
  end

  -- Mappings:
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  -- stylua: ignore start
  buf_keymap('n', 'gd', [[<Cmd>Telescope lsp_definitions<CR>]],
    { desc = 'Go to definition' })
  buf_keymap('n', 'gD', [[<Cmd>Telescope lsp_type_definitions<CR>]],
    { desc = 'Go to type definitions' })
  buf_keymap('n', 'gr', [[<Cmd>Telescope lsp_references<CR>]],
    { desc = 'Go to references' })
  buf_keymap('n', 'gi', [[<Cmd>Telescope lsp_implementations<CR>]],
    { desc = 'Go to implementations' })
  buf_keymap('n', '<leader>sd', [[<Cmd>Telescope diagnostics bufnr=0<CR>]],
    { desc = 'Search all diagnostics if current buffer' })
  buf_keymap('n', '<leader>ss', [[<Cmd>Telescope lsp_document_symbols<CR>]],
    { desc = 'Search all symbols in current buffer' })
  buf_keymap('n', '<leader>k', vim.lsp.buf.hover,
    { buffer = bufnr, desc = 'Show hover' })
  buf_keymap('n', '<leader>K', vim.lsp.buf.signature_help,
    { buffer = bufnr, desc = 'Show signature help' })
  buf_keymap('n', '<leader>wa', function()
    vim.ui.input({
      prompt = 'Workspace folder to be added',
      default = vim.fn.expand '%:p:h',
    }, function(dir)
      if dir then
        vim.lsp.buf.add_workspace_folder(dir)
      end
    end)
  end, { buffer = bufnr, desc = 'Add workspace folder' })
  buf_keymap('n', '<leader>wd', function()
    vim.ui.select(vim.lsp.buf.list_workspace_folders(), {
      prompt = 'Workspace folder to be removed',
    }, function(dir)
      if dir then
        vim.lsp.buf.remove_workspace_folder(dir)
      end
    end)
  end, { buffer = bufnr, desc = 'Remove workspace folder' })
  buf_keymap('n', '<leader>cn', function()
    return ':IncRename ' .. vim.fn.expand '<cword>'
  end, { expr = true, desc = 'Change variable name' })
  buf_keymap('n', '<leader>.', vim.lsp.buf.code_action, { desc = 'Show code action' })
  -- stylua: ignore end
  local ft = vim.bo[bufnr].filetype
  local have_nls = #require("null-ls.sources").get_available(
      ft,
      "NULL_LS_FORMATTING"
    ) > 0
  local format = function(opts)
    opts = vim.tbl_extend("keep", opts or {}, {
      async = true,
      bufnr = bufnr,
      filter = function(c)
        if have_nls then
          return c.name == "null-ls"
        end
        return c.name ~= "null-ls"
      end,
    })
    vim.lsp.buf.format(opts)
  end
  buf_keymap({ "n", "v" }, "<leader>f", format, { desc = "Format" })
  if client.supports_method "textDocument/formatting" then
    vim.api.nvim_clear_autocmds {
      group = format_group,
      buffer = bufnr,
    }
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = format_group,
      buffer = bufnr,
      callback = function()
        format { async = false }
      end,
    })
  end
end

---@class LspOptions
---@field root_dir? fun(filename, bufnr): string
---@field name? string
---@field filetypes? string[]|string
---@field autostart? boolean
---@field single_file_support? boolean
---@field on_new_config? fun(config, root_dir)
---@field capabilities table <string, string|table|boolean|function>
---@field cmd? string[]
---@field handlers? function[]
---@field init_options? table<string, string|table|boolean>
---@field on_attach? fun(client, bufnr)
---@field settings? table<string, string|table|boolean>

---@class LspConfig
---@field disabled? boolean Whether to disable this lsp
---@field setup_capabilities? fun(capabilities:table):table Setup capabilities
---@field options? LspOptions Options to be passed to lspconfig

---@param opts LspConfig|string Config for lspconfig, if string it is treated as a lua module name
---@param reload? boolean Whether to reload the module
---@return LspConfig options opts Processed lspconfig
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
  if config.disabled then
    return
  end
  local options = config.options or {}
  local function on_attach(client, bufnr)
    on_attach_common(client, bufnr)
    if options.on_attach then
      options.on_attach(client, bufnr)
    end
  end

  local capabilities = make_capabilities()
  if config.setup_capabilities then
    config.setup_capabilities(capabilities)
  end
  local new_options = vim.deepcopy(options)
  new_options.on_attach = on_attach
  new_options.capabilities = capabilities
  return lspconfig[server].setup(new_options)
end

---@type table<string, LspConfig|string>
M.configs = {
  julials = "lsp.julials",
  sumneko_lua = "lsp.sumneko_lua",
  bashls = {
    options = {
      filetypes = { "sh", "bash" },
    },
  },
  taplo = {},
  texlab = {},
  jsonls = {
    options = {
      cmd = { "vscode-json-languageserver", "--stdio" },
    },
  },
  ltex = {
    options = {
      filetypes = { "plaintex", "tex", "bib", "markdown", "rst" },
    },
  },
}

M.setup = function()
  -- auto reload servers' config when config changes
  util.create_bufwrite_autocmd {
    pattern = "lsp/*.lua",
    callback = function(args)
      local server = vim.fs.basename(args.file):gsub("%.lua$", "")
      if server == "init" then -- reload this file
        return util.reload("lsp").setup()
      end
      local config = process_config(M.configs[server], true)
      setup_server(server, config)
    end,
    group = vim.api.nvim_create_augroup("LspReload", { clear = true }),
  }
  keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
  keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
  for server, config in pairs(M.configs) do
    setup_server(server, process_config(config))
  end
end

return M

-- vim:tw=76:ts=2:sw=2:et
