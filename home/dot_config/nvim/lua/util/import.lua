--- Lazy import module

---@class Import

---@class Import.Lazy
---
---
---@field _cache any | nil The cached value of the lazy object
---
--- A abstract class for lazy object
local Lazy = {}

function Lazy.new()
  local self = { _cache = nil }
  return self
end

---@class Import.LazyMod: Import.Lazy
---@field _mod string
local LazyMod = {}
setmetatable(LazyMod, { __index = Lazy })

---@class Import.LazySub: Import.Lazy
---@field _parent Import.Lazy
---@field _sub string
local LazySub = {}
setmetatable(LazySub, { __index = Lazy })

--- Create a sub lazy object from given lazy object and key
---
---@param self Import.Lazy
---@param key string
---@return Import.LazySub
function Lazy:get(key)
  local parent = self
  local sub = key
  return LazySub.new(parent, sub)
end

--- Create a closure from given lazy object
---
---@return fun(...): any
function Lazy:callable()
  return function(...)
    local f = self:mtl()
    return f(...)
  end
end

--- Create a closure with pre-defined args from given lazy object
---
--- @param ... unknown
--- @return fun(): any
function Lazy:closure(...)
  local args = { ... }
  return function()
    local f = self:mtl()
    return f(unpack(args))
  end
end

--- Create a lazy table from given lazy object
---
--- Note, this is not working for iterate by `pairs` or `ipairs`.
--- This is because the `__pairs` metamethod are not supported in LuaJIT by default.
--- So `vim.tbl_extend` will not works as well.
---@return table
function Lazy:tbl()
  return setmetatable({}, {
    __index = function(_, key)
      local mtl = self:mtl()
      return mtl[key]
    end,
  })
end

--- Meterialize the lazy object
---
---@return any
function Lazy:mtl() error "Not implemented" end

--- Create a lazily loaded module
---
---@param mod string
---@return Import.LazyMod
function LazyMod.new(mod)
  local obj = Lazy.new()
  setmetatable(obj, { __index = LazyMod })
  obj._mod = mod
  return obj
end

--- Require the module if not required
---
---@return any
function LazyMod:mtl()
  if self._cache == nil then self._cache = require(self._mod) end
  return self._cache
end

--- Create a lazily indexed value from a parent lazy object
---
---@param parent Import.Lazy
---@param key string
---@return Import.LazySub
function LazySub.new(parent, key)
  local obj = Lazy.new()
  setmetatable(obj, { __index = LazySub })
  obj._parent = parent
  obj._sub = key
  return obj
end

--- Get the value of the indexed key from the parent lazy object
---
---@return any
function LazySub:mtl()
  if self._cache == nil then
    local p = self._parent:mtl()
    self._cache = p[self._sub]
  end
  return self._cache
end

---@param mod string
---
---@return Import.LazyMod
local function import(mod) return LazyMod.new(mod) end

return import
