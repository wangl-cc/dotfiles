local parsers = require('nvim-treesitter.parsers')
local ts_utils = require('nvim-treesitter.ts_utils')
local match = vim.fn.match

local M = {}

M.options = {
  pattern = [[\v(function|macro|module|class|struct)_(definition|declaration)]],
  icons = {
    function_definition = ' ',
    function_declaration = ' ',
    macro_definition = '@',
    macro_declaration = '@',
    module_definition = ' ',
    module_declaration = ' ',
    class_definition = 'פּ ',
    class_declaration = 'פּ ',
    struct_definition = 'פּ ',
    struct_declaration = 'פּ ',
  },
  identifiers = {
    identifier = true,
    dot_index_expression = true,
    method_index_expression = true,
  },
}

function M.options.name_parser(node)
  local node_name
  local identifiers = M.options.identifiers
  for i = 0, node:child_count(), 1 do
    local child = node:child(i)
    if identifiers[child:type()] then
      local sr, sc, er, ec = child:range()
      node_name = vim.api.nvim_buf_get_text(
        0, sr, sc, er, ec, {})[1]
      break
    end
    if child:type() == 'parameters' then
      break
    end
  end
  if not node_name then
    local parent = node:parent()
    if parent:type() == 'field' then
      local prev = node:prev_named_sibling()
      if identifiers[prev:type()] then
        -- for lua function like:
        -- local M = { f = function() end }
        local sr, sc, er, ec = prev:range()
        node_name = vim.api.nvim_buf_get_text(
          0, sr, sc, er, ec, {})[1]
      end
    elseif parent:type() == 'expression_list' then
      -- for lua function like
      -- local f = function() end
      local var = parent:prev_named_sibling():child(0)
      if identifiers[var:type()] then
        local sr, sc, er, ec = var:range()
        node_name = vim.api.nvim_buf_get_text(
          0, sr, sc, er, ec, {})[1]
      end
    end
  end
  return node_name
end

function M.options.render(entry)
  local icon = M.options.icons[entry.type]
  if icon then
    return table.concat { icon, entry.name }
  else
    return entry.name
  end
end

function M.ts_statusline(opt)
  if not parsers.has_parser() then
    return opt.start
  end
  local reverse = opt.reverse or false
  local separator = opt.separator -- nil means no separator
  -- If pattern changes, render, name_parser should change for new fould nodes
  local pattern = opt.pattern or M.options.pattern
  local name_parser = opt.name_parser or M.options.name_parser
  local render = opt.render or M.options.render

  local node = ts_utils.get_node_at_cursor()
  if not node then
    return
  end

  local entrys = {}
  while node do
    local node_type = node:type()
    if match(node_type, pattern) ~= -1 then
      local node_name = name_parser(node) or '[anonymous]'
      local entry = render {
        type = node_type,
        name = node_name,
      }
      if reverse then
        table.insert(entrys, entry)
        if separator then
          table.insert(entrys, separator)
        end
      else
        table.insert(entrys, 1, entry)
        if separator then
          table.insert(entrys, 1, separator)
        end
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
  elseif separator ~= nil then
    if reverse then
      table.remove(entrys)
    else
      table.remove(entrys, 1)
    end
  end
  return entrys
end

-- This is not in used, just for reference and test
function M.ts_statusline_string(opt)
  opt = opt or {}
  local separator = opt.separator or ' '
  opt.separator = nil
  local entrys = M.ts_statusline(opt)
  if entrys and #entrys > 0 then
    return table.concat(entrys, separator)
  end
  return ''
end

return M
