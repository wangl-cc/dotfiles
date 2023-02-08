-- A convenience way to register keymaps like `which-key.nvim`

local M = {}

---@alias KeymapMode string

---@private
--- Wrap mode in a table if it is not a table
---@generic T
---@param mode T|T[]
---@return T[]
local warp = function(mode)
  return type(mode) == "table" and mode or { mode }
end

---@private
--- Pop the given key from given table if it exists, otherwise return default
---@param tbl table
---@param key integer|string
---@param default? any
---@return any|nil
local pop = function(tbl, key, default)
  if tbl[key] == nil then
    return default
  end
  local val = tbl[key]
  tbl[key] = nil
  return val
end

---@alias KeymapCallback fun(opts: table): string|nil

---@private
--- Options acccepted by `vim.keymap.set`
---@class KeymapOption
---@field nowait? boolean Don't wait for additional keys if true
---@field silent? boolean Don't echo the command if true
---@field script? boolean
---@field unique? boolean Don't override existing mappings
---@field expr? boolean The callback returns a string
---@field replace_keycodes? boolean Replace keycodes in the callback result
---@field noremap? boolean Make a mapping non-recursive
---@field remap? boolean Make a mapping recursive, override noremap if it not nil
---@field callback? KeymapCallback Function called when mapping is executed
---@field desc? string Descripation of mapping.

---@private
--- Process options for `vim.api.nvim_set_keymap`
---@param opts KeymapOption Options of keymap to be setup
---@return KeymapOption opts Modified options for keymap
local setup_opts = function(opts)
  if opts.expr and opts.replace_keycodes ~= false then
    opts.replace_keycodes = true
  end
  if opts.remap ~= nil then -- always overrides noremap when remap is not nil
    opts.noremap = not opts.remap
    opts.remap = nil
  end
  return opts
end

---@private
--- Set keymap for given buffer when buffer is not nil, otherwise set it globally
---@param buffer buffer|nil
---@param mode KeymapMode[]
---@param lhs string
---@param rhs string
---@param opts KeymapOption
local set_keymap = function(buffer, mode, lhs, rhs, opts)
  if buffer then
    for _, m in ipairs(mode) do
      vim.api.nvim_buf_set_keymap(buffer, m, lhs, rhs, opts)
    end
  else
    for _, m in ipairs(mode) do
      vim.api.nvim_set_keymap(m, lhs, rhs, opts)
    end
  end
end

-- Extended KeymapOption with a additional field `mode`
---@class KeymapSpec
---@field mode KeymapMode|KeymapMode[] Mode of keymap
---@field nowait? boolean Don't wait for additional keys if true
---@field silent? boolean Don't echo the command if true
---@field script? boolean
---@field unique? boolean Don't override existing mappings
---@field expr? boolean The callback returns a string
---@field replace_keycodes? boolean Replace keycodes in the callback result
---@field noremap? boolean Make a mapping non-recursive
---@field remap? boolean Make a mapping recursive, override noremap if it not nil
---@field callback? KeymapCallback Function called when mapping is executed
---@field desc? string Descripation of mapping.""

---@alias Cmd string
---@alias KeymapTree table<string, KeymapSpec|KeymapTree|KeymapCallback|Cmd>

---@private
--- Register keymaps with given tree
---@param buffer buffer|nil
---@param mode KeymapMode[]
---@param prefix string
---@param tree KeymapTree
---@param suffix string
---@param defaults KeymapOption
local function register(buffer, mode, prefix, tree, suffix, defaults)
  for key, node in pairs(tree) do
    if type(node) == "table" then
      if node[1] ~= nil or node.callback ~= nil then -- KeymapSpec
        local lhs = prefix .. key .. suffix
        local opts = vim.tbl_extend("force", defaults, node)
        local rhs = pop(opts, 1, "")
        if type(rhs) == "function" then
          opts.callback = rhs
          rhs = ""
        end
        mode = warp(pop(opts, "mode", mode))
        set_keymap(buffer, mode, lhs, rhs, setup_opts(opts))
      else -- KeymapTree
        register(buffer, mode, prefix .. key, node, suffix, defaults)
      end
    elseif type(node) == "function" then -- KeymapCallback
      local rhs = ""
      local opts = vim.deepcopy(defaults)
      opts.callback = node
      set_keymap(buffer, mode, prefix .. key .. suffix, rhs, opts)
    elseif type(node) == "string" then -- Cmd
      set_keymap(buffer, mode, prefix .. key .. suffix, node, defaults)
    else
      error("Cannot set keymap with value of type " .. type(node))
    end
  end
end

--- Extended KeymapSpec with additional fields: `buffer`, `prefix` and `suffix`
---@class KeymapDefaults
---@field buffer? buffer Buffer to set keymap
---@field prefix? string Prefix of keymap
---@field suffix? string Suffix of keymap
---@field mode? KeymapMode|KeymapMode[] Mode to set keymap
---@field nowait? boolean Don't wait for additional keys if true
---@field silent? boolean Don't echo the command if true
---@field script? boolean
---@field unique? boolean Don't override existing mappings
---@field expr? boolean The callback returns a string
---@field replace_keycodes? boolean Replace keycodes in the callback result
---@field noremap? boolean Make a mapping non-recursive
---@field remap? boolean Make a mapping recursive, override noremap if it not nil
---@field callback? KeymapCallback Function called when mapping is executed
---@field desc? string Descripation of mapping.

--- Register keymaps with given tree and given default options
---
--- The node of tree can be:
--- - string, which is a command to be executed
--- - function, which is a callback to be executed
--- - KeymapSpec, which is a table describes a keymap, @see KeymapSpec
--- - KeymapTree, a sub tree of keymaps
--- Example:
--- ```lua
--- register({
---  t = {
---    t = "<Cmd>Neotree toggle<CR>",
---  },
---  f = vim.lsp.buf.formatting,
---  k = {
---    callback = vim.lsp.buf.hover,
---    desc = "Show hover",
---  }
--- }, { prefix = "<leader>" })
--- ```
---@param tree KeymapTree
---@param opts? KeymapDefaults
M.register = function(tree, opts)
  opts = opts and vim.deepcopy(opts) or {}
  -- Pop some fields from opts to make it a KeymapOption
  local buffer = pop(opts, "buffer") ---@type number|nil
  local prefix = pop(opts, "prefix", "") ---@type string
  local suffix = pop(opts, "suffix", "") ---@type string
  local mode = warp(pop(opts, "mode", { "n" })) ---@type KeymapMode[]
  ---@diagnostic disable-next-line: cast-type-mismatch
  ---@cast opts KeymapOption
  register(buffer, mode, prefix, tree, suffix, setup_opts(opts))
end

return M
