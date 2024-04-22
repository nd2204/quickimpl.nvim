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

local ns_class_query = [[
(namespace_definition
	name: (namespace_identifier) @name
    body: (declaration_list
    	(class_specifier) @ns_class))
]]

local class_query = [[
  ((class_specifier) @class)
]]

local function_query = [[
(declaration
	type: [(type_identifier) (primitive_type)] @type
	declarator: (function_declarator) @declarator)
]]

local constructor_query = [[

]]

local destructor_query = [[

]]

---@return table
local function parse_function(node)
  local parsed = {}
  local captured = ts_util.get_query_capture(node, 'cpp', function_query)
  for n in captured do
    parsed[n:type()] = ts_util.ts.get_node_text(n, 0)
  end
  return parsed
end

local function parse_ns_class()
end

--------------------------------------------------------------------------------
--- Local functions
--------------------------------------------------------------------------------
function M.callback(params)
  ---Get full file path of a buffer
  local path = api.nvim_buf_get_name(0)

  ---get parser
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  local captured = ts_util.get_query_capture(root, 'cpp', ns_class_query)
  for node in captured do
    -- debug.print_node_sexpr(node)
    print(vim.treesitter.get_node_text(node, 0))
    print('')
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
