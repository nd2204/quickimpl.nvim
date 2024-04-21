local M = {}

local api = vim.api
local ts = vim.treesitter
-- local uv = vim.loop

--------------------------------------------------------------------------------
--- Class Properties
--------------------------------------------------------------------------------
local supported_args = {
 'definition', 'prototype'
}

M.name = 'QIGenerate'

M.opts = {
  bang = false,
  bar = false,
  nargs = 1,
  addr = 'other',
  complete = function()
    return supported_args
  end,
}

--------------------------------------------------------------------------------
--- Local functions
--------------------------------------------------------------------------------
function M.callback(params)
  ---Get full file path of a buffer
  local path = api.nvim_buf_get_name(0)

  ---get parser
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  print(root:next_sibling():sexpr())

  -- local header = require('quickimpl.header')
  -- local source = require('quickimpl.source')
  -- print(root:sexpr())
  -- if params[1] == supported_args[1]  then
  --   local namespaces = header.get_declarations(root)
  --   source.insert_header(path)
  --   source.define_methods(namespaces)
  -- end
end

return M
