-- A convenience way to register keymaps like `which-key.nvim`

---@alias KeymapMode
---| '"n"' -- Normal mode
---| '"s"' -- Select mode
---| '"x"' -- Visual mode
---| '"v"' -- Visual and Select mode
---| '"o"' -- Operator-pending mode
---| '"i"' -- Insert mode
---| '"c"' -- Command-line mode
---| '"l"' -- Insert, Command-line, and Lang-Arg mode
---| '"t"' -- Terminal mode
---| '"o"' -- Operator-pending mode
---| '"m"' -- Motion mode

---@private
--- Wrap mode in a table if it is not a table
---@param mode KeymapMode|KeymapMode[]
---@return KeymapMode[]
local function warp(mode) return type(mode) == "table" and mode or { mode } end

---@private
--- Pop the given key from given table if it exists, otherwise return default
---@param tbl table
---@param key integer|string
---@param default? any
---@return any|nil
local function pop(tbl, key, default)
  if tbl[key] == nil then return default end
  local val = tbl[key]
  tbl[key] = nil
  return val
end

---@alias KeymapCallback fun(opts: table): string|nil

---@private
---@class KeymapOption: vim.api.keyset.keymap
---@field remap? boolean

---@private
--- Process options for `vim.api.nvim_set_keymap`
---@param opts KeymapOption Options of keymap to be setup
---@return KeymapOption opts Modified options for keymap
local function setup_opts(opts)
  if opts.expr and opts.replace_keycodes ~= false then
    opts.replace_keycodes = true
  end
  if opts.remap ~= nil then -- always overrides noremap when remap is not nil
    opts.noremap = not opts.remap
    opts.remap = nil
  else -- default to noremap
    opts.noremap = opts.noremap ~= false
  end
  return opts
end

---@private
--- Set keymap for given buffer when buffer is not nil, otherwise set it globally
---@param buffer number|nil
---@param modes KeymapMode[]
---@param lhs string
---@param rhs string
---@param opts KeymapOption
local function set_keymap(buffer, modes, lhs, rhs, opts)
  if buffer then
    for _, m in ipairs(modes) do
      vim.api.nvim_buf_set_keymap(buffer, m, lhs, rhs, opts)
    end
  else
    for _, m in ipairs(modes) do
      vim.api.nvim_set_keymap(m, lhs, rhs, opts)
    end
  end
end

-- Extended KeymapOption with a additional field `mode`
---@class KeymapSpec: KeymapOption
---@field mode? KeymapMode|KeymapMode[] Mode of keymap

---@alias Cmd string Vim command to be executed
---@alias KeymapTree table<string, KeymapSpec|KeymapTree|KeymapCallback|Cmd>

---@private
--- Register keymaps with given tree
---@param buffer number|nil
---@param mode KeymapMode[]
---@param prefix string
---@param tree KeymapTree
---@param suffix string
---@param defaults KeymapOption
local function register_impl(buffer, mode, prefix, tree, suffix, defaults)
  for key, node in pairs(tree) do
    if type(node) == "table" then
      if node[1] ~= nil or node.callback ~= nil then -- KeymapSpec
        local lhs = prefix .. key .. suffix
        ---@type KeymapSpec
        local opts = vim.tbl_extend("force", defaults, node)
        local rhs = pop(opts, 1, "")
        if type(rhs) == "function" then
          opts.callback = rhs
          rhs = ""
        end
        local local_mode = warp(pop(opts, "mode", mode))
        set_keymap(buffer, local_mode, lhs, rhs, setup_opts(opts))
      else -- KeymapTree
        register_impl(buffer, mode, prefix .. key, node, suffix, defaults)
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
---@class KeymapDefaults: KeymapSpec
---@field buffer? number Buffer to set keymap
---@field prefix? string Prefix of keymap
---@field suffix? string Suffix of keymap

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
local function register(tree, opts)
  opts = opts and vim.deepcopy(opts) or {}
  -- Pop some fields from opts to make it a KeymapOption
  local buffer = pop(opts, "buffer") ---@type number|nil
  local prefix = pop(opts, "prefix", "") ---@type string
  local suffix = pop(opts, "suffix", "") ---@type string
  local mode = warp(pop(opts, "mode", { "n" })) ---@type KeymapMode[]
  ---@diagnostic disable-next-line: cast-type-mismatch
  ---@cast opts KeymapOption
  register_impl(buffer, mode, prefix, tree, suffix, setup_opts(opts))
end

return register
