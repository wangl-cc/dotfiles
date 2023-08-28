--- Lazy import module

---@class Import

---@class Import.Lazy
---@field get fun(self: Import.Lazy, key: string): Import.LazySub
---@field with fun(self: Import.Lazy, ...): fun(): nil
---@field with_fun fun(self: Import.Lazy, args: fun(): ...): fun(): nil
---@field tbl fun(self: Import.Lazy): table
---@field mtl fun(self: Import.Lazy): any Meterialize the lazy object
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

  --- Create a sub lazy object from given lazy object and key
  ---
  ---@param key string
  ---@return Import.LazySub
  function obj:get(key)
    local parent = self
    local sub = key
    return LazySub.new(parent, sub)
  end

  --- Create a closure from given lazy object and args
  ---
  ---@param ... unknown
  ---@return fun(): nil
  function obj:with(...)
    local args = { ... }
    return function()
      local f = self:mtl()
      return f(unpack(args))
    end
  end

  --- Create a closure from given lazy object and given function
  ---
  --- The function will be called when the closure is called.
  ---@param fun fun(): ...
  ---@return fun(): nil
  function obj:with_fun(fun)
    return function()
      local f = self:mtl()
      f(fun())
    end
  end

  --- Create a lazy table from given lazy object
  ---
  --- Note, this is not working for iterate by `pairs` or `ipairs`.
  --- This is because the `__pairs` metamethod are not supported in LuaJIT by default.
  --- So `vim.tbl_extend` will not works as well.
  ---@return table
  function obj:tbl()
    return setmetatable({}, {
      __index = function(_, key)
        local mtl = self:mtl()
        return mtl[key]
      end,
    })
  end

  return obj
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

--- Lazy import a module
---
--- ```lua
--- local foo = import "foo" -- foo a lua module to be imported
--- local bar = foo:get "bar" -- bar is a key of foo
--- bar:with() -- return a closure to call foo.bar
--- bar:with(1, 2, 3) -- return a closure to call foo.bar(1, 2, 3)
--- -- return a closure to call foo.bar(1, 2, 3), but the args will be evaluated when the closure is called
--- bar:with_fun(function()
---   return 1, 2, 3
--- end)
---@param mod string
---@return Import.LazyMod
local import = function(mod) return LazyMod.new(mod) end

return import
