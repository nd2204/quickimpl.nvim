local ts_util = require "quickimpl.treesitter"
local Type    = require "quickimpl.treesitter.node.cpp_type"
local ts = vim.treesitter

-------------------------------------------------------------------------------

---@class TemplateNode
---@field node (TSNode)
---@field bufnr integer
---@field param_list (TSNode|nil)
local TemplateNode = {}
TemplateNode.__index = TemplateNode

-------------------------------------------------------------------------------

---@param node (TSNode|nil)
TemplateNode.new = function(node)
  local self = setmetatable({}, TemplateNode)
  if node == nil or node:type() ~= Type.TEMPLATE_DECLARATION then
    return nil
  end
  self.node = node
  self.param_list = ts_util.first_child_with_type(
    Type.TEMPLATE_PARAMETER_LIST,
    self.node
  )
  return self
end

-------------------------------------------------------------------------------

---@return TSNode
function TemplateNode:get_node()
  return self.node
end

---@return string
function TemplateNode:get_template_decl()
  assert(self.param_list)
  return 'template'..ts.get_node_text(self.param_list, self.bufnr)..'\n'
end

---@return string
function TemplateNode:get_param_list()
  assert(self.param_list)
  return ts.get_node_text(self.param_list, self.bufnr)
end

---@return string
function TemplateNode:get_arg_list()
  if self.param_list == nil or self.param_list:child_count() == 0 then
    return '<>'
  end
  local arg_list = '<'
  for child in self.param_list:iter_children() do
    local type_identifier = ts_util.first_child_with_type(Type.TYPE_IDENTIFIER, child)
    if type_identifier then
      arg_list = arg_list..ts.get_node_text(type_identifier, self.bufnr)..','
    elseif child:named() then
      arg_list = arg_list..','
    end
  end
  arg_list = string.gsub(arg_list, ",$", ">")
  return arg_list
end

-------------------------------------------------------------------------------

return TemplateNode
