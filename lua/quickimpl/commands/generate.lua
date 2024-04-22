local M = {}

local api = vim.api
local ts = vim.treesitter
local ts_util = require('quickimpl.treesitter')
local debug = ts_util.debug
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

-- local function parse_function(node)
--   local parsed = {}
--   local functions = ts_util.get_query_capture(node, 'cpp', method_query)
--   for i = 1, #functions do
--     table.insert(parsed, i, {
--       type = ts.get_node_text(functions[capture_names.func_typename], 0),
--       decl = ts.get_node_text(functions[capture_names.func_decl], 0)
--     })
--   end
--   vim.print(parsed)
-- end

--------------------------------------------------------------------------------
--- Local functions
--------------------------------------------------------------------------------
function M.callback(params)
  ---Get full file path of a buffer
  local path = api.nvim_buf_get_name(0)

  ---get parser
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  local query = NamespaceQuery.new()
  local namespaces = query:get_query_capture(root, 'cpp')
  for i = 1, #namespaces do
    vim.print(string.format("[%d/%d]", i, #namespaces))
    vim.print(namespaces[i]['ns_decl_list']:sexpr())
  end


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
