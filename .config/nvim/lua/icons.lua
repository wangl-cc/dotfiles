--[[
Those icons is modified from onsails/lspkind.nvim
Author: Andrey Kuznetsov
URL: https://github.com/onsails/lspkind.nvim
LISENCE: MIT
--]]

local M = {}

M.icons = {
  Text = '',
  Method = '',
  Function = '',
  Constructor = '',
  Field = 'ﰠ',
  Variable = '',
  Interface = '',
  Class = 'פּ',
  Module = '',
  Property = 'ﰠ',
  Unit = '',
  Value = '',
  Enum = '',
  Keyword = '',
  Snippet = '',
  Color = '',
  File = '',
  Reference = '',
  Folder = '',
  EnumMember = '',
  Constant = '',
  Event = '',
  Struct = 'פּ',
  Operator = '',
  TypeParameter = '',
}

M.ts_icons = {
  function_definition = ' ',
  function_declaration = ' ',
  macro_definition = '@',
  macro_declaration = '@',
  module_definition = ' ',
  class_definition = 'פּ ',
  class_declaration = 'פּ ',
  struct_definition = 'פּ ',
  struct_declaration = 'פּ ',
}

return M
