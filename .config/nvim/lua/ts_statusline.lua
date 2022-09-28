local parsers = require('nvim-treesitter.parsers')
local ts_utils = require('nvim-treesitter.ts_utils')
local ts_icons = require('icons').ts_icons

local function get_node_name(buffer, node)
  local node_name
  for i = 0, node:child_count(), 1 do
    local child = node:child(i)
    if child:type() == 'identifier' then
      local sr, sc, er, ec = child:range()
      node_name = vim.api.nvim_buf_get_text(
        buffer, sr, sc, er, ec, {})[1]
      break
    end
    if child:type() == 'parameters' then
      break
    end
  end
 -- for lua function like local f = function() end
  if not node_name then
    local prev = node:prev_named_sibling()
    if prev:type() == 'identifier' then
      local sr, sc, er, ec = prev:range()
      node_name = vim.api.nvim_buf_get_text(
        buffer, sr, sc, er, ec, {})[1]
    end
  end
  return node_name
end

local function ts_statusline(opt)
  if not parsers.has_parser() then
    return opt.start
  end
  local buffer = opt.buffer or 0
  -- If reverse, separator should to change
  local reverse = opt.reverse or false
  local separator = opt.separator or ' → '
  -- If pattern changes, render, name_parser should change for new fould nodes
  local patterns = opt.patterns or { 'definition', 'declaration' }
  local name_parser = opt.name_parser or get_node_name
  local render = opt.render or function(entry)
    local icon = ts_icons[entry.type]
    if icon then
      return { icon, entry.name }
    else
      return entry.name
    end
  end

  local node = ts_utils.get_node_at_cursor()
  if not node then
    return
  end

  local entrys = {}
  while node do
    local node_type = node:type()
    local match = false
    for _, pattern in ipairs(patterns) do
      if node_type:find(pattern) then
        match = true
      end
    end
    if match then
      local node_name = name_parser(buffer, node) or 'λ'
      local entry = render {
        type = node_type,
        name = node_name,
      }
      if reverse then
        table.insert(entrys, entry)
        table.insert(entrys, separator)
      else
        table.insert(entrys, 1, separator)
        table.insert(entrys, 1, entry)
      end
    end
    node = node:parent()
  end
  if opt.start then
    if reverse then
      table.insert(entrys, opt.start)
    else
      table.insert(entrys, 1, opt.start)
    end
  end
  return entrys
end

return ts_statusline
