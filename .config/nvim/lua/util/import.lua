---@class Import

---@class Import.Lazy
---@field func fun(self: Import.Lazy): fun()
---@field table fun(self: Import.Lazy): table
---@field mtl fun(self: Import.Lazy): any
local Lazy = {}

---@class Import.LazyMod: Import.Lazy
---@field _mod string
local LazyMod = {}

---@class Import.LazySub: Import.Lazy
---@field _parent Import.Lazy
---@field _sub string
local LazySub = {}

---@return Import.Lazy
function Lazy.new()
  local obj = setmetatable({}, Lazy)

  --- Return a lazy function from given lazy object
  ---@return fun(...): any
  function obj:fun()
    return function(...)
      local mtl = self:mtl()
      return mtl(...)
    end
  end

  --- Create a lazy table from given lazy object
  ---@return table
  function obj:table()
    return setmetatable({}, {
      __index = function(_, key)
        local mtl = self:mtl()
        return mtl[key]
      end,
    })
  end

  return obj
end

---@param key string
---@return Import.LazySub
function Lazy:__index(key)
  local parent = self
  local sub = key
  return LazySub.new(parent, sub)
end

---@param mod string
---@return Import.LazyMod
function LazyMod.new(mod)
  local obj = Lazy.new()

  ---@cast obj Import.LazyMod
  obj._mod = mod

  function obj:mtl() return require(self._mod) end

  return obj
end

---@param parent Import.Lazy
---@param sub string
---@return Import.LazySub
function LazySub.new(parent, sub)
  local obj = Lazy.new()

  ---@cast obj Import.LazySub
  obj._parent = parent
  obj._sub = sub

  function obj:mtl()
    local p = self._parent:mtl()
    return p[self._sub]
  end

  return obj
end

--- Lazy import
---
--- Usage:
--- ```lua
---   local import = require("import")
---   local foo = import("foo"):table() -- the foo module is not loaded yet
---   foo.bar -- the foo module is loaded now
---   local qux = import("baz").qux:fun() -- the baz module is not loaded yet
---   qux() -- the baz module is loaded now
--- ```
---
---@param mod string
---@return Import.LazyMod
local import = function(mod) return LazyMod.new(mod) end

return import
