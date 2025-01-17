local M = {}

local components = require "putil.lualine.components"

M.components = components

local util = {}

---@alias LuaLineComponent string|table|function():string

---@class LuaLineSections
---@field lualine_a? LuaLineComponent[]
---@field lualine_b? LuaLineComponent[]
---@field lualine_c? LuaLineComponent[]
---@field lualine_x? LuaLineComponent[]
---@field lualine_y? LuaLineComponent[]
---@field lualine_z? LuaLineComponent[]

M.util = util

function util.const_string(str)
  return function() return str end
end

--- Make the lualine_z section display the current time
---@param sections LuaLineSections
---@return LuaLineSections
function util.with_time(sections)
  sections.lualine_z = { components.time }
  return sections
end

--- Make the lualine_y section display the current location
--- and the lualine_z section display the current time
---
--- @param sections LuaLineSections
--- @return LuaLineSections
function util.with_time_and_location(sections)
  sections.lualine_y = { components.location }
  sections.lualine_z = { components.time }
  return sections
end

M.extensions = {}

--- Register a new extension for given filetype(s)
---@param filetypes string|string[]
---@param sections LuaLineSections
function M.registry_extension(filetypes, sections)
  if type(filetypes) == "string" then filetypes = { filetypes } end
  table.insert(M.extensions, {
    filetypes = filetypes,
    sections = sections,
  })
end

M.registry_extension(
  "lazy",
  util.with_time {
    lualine_a = { util.const_string "LAZY" },
    lualine_b = {
      function()
        local lazy_status = require("lazy").stats()
        return ("Loaede: %d/%d"):format(lazy_status.loaded, lazy_status.count)
      end,
    },
  }
)

M.registry_extension(
  {
    "lspinfo",
    "checkhealth",
    "noice",
  },
  util.with_time_and_location {
    lualine_a = { components.uppercase_filetype },
  }
)

M.registry_extension(
  { "help", "man" },
  util.with_time_and_location {
    lualine_a = { components.uppercase_filetype },
    lualine_b = {
      { "filename", file_status = false },
    },
  }
)

M.registry_extension(
  "query",
  util.with_time_and_location {
    lualine_a = { util.const_string "TREE" },
  }
)

local lualine_x = {}

M.sections = {
  lualine_a = { "mode" },
  lualine_b = {
    components.git_branch,
    components.git_diff,
    components.diagnostics,
  },
  lualine_c = {
    components.indent,
    components.line_width,
    components.file_encoding,
    components.file_format,
    components.language_server,
    components.linter,
    components.formatter,
  },
  lualine_x = lualine_x,
  lualine_y = { components.location },
  lualine_z = { components.time },
}

local priorities = {}

---@alias Component table

--- Add a plugin component at lualine_x section
---
---@param component Component Component to be added
---@param priority? number Priority of the component, default is 50
---
--- Components with higher priority will be added to the right of the section,
--- If the priority is the same, the later added component will be added to the left.
function M.add_component(component, priority)
  Util.assert_type(component, "table")
  if priority then
    Util.assert_type(priority, "number")
  else
    priority = 50
  end
  for i, p in ipairs(priorities) do
    if p >= priority then
      table.insert(lualine_x, i, component)
      table.insert(priorities, i, priority)
      return
    end
  end
  table.insert(lualine_x, component)
  table.insert(priorities, priority)
end

return M
