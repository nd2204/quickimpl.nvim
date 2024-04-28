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

local function_blacklist = {
  ['static'] = true,
  ['number_literal'] = true,
}

local function is_function_blacklisted(type, text)
  return function_blacklist[type] or function_blacklist[text]
end

---@param node (TSNode)
local function parse_function(node)
  local parsed = {}
  local type, node_txt
  for child in node:iter_children() do
    type = child:type()
    node_txt = ts.get_node_text(child, 0)
    if is_function_blacklisted(type, node_txt) then return nil end
    if child:named() then table.insert(parsed, node_txt) end
  end
  return parsed
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

  local node = assert(ts_util.get_cursor_declaration())
  vim.print(parse_function(node))

  -- vim.print(ts.get_captures_at_cursor())
  -- local query = NamespaceQuery.new('ns_name', 'ns_decl_list', 'ns')
  -- local namespaces = query:get_query_capture(root, 'cpp')
  -- for i = 1, #namespaces do
  --   vim.print(string.format("[%d/%d]", i, #namespaces))
  --   local decl = namespaces[i]['ns_decl_list']
  --   vim.print(decl:sexpr())
  --   for child in decl:iter_children() do
  --     if child:type() == 'class_specifier' then
  --       vim.print(ts.get_node_text(child, 0))
  --     end
  --   end
  -- end


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
