local ts            = vim.treesitter
local ts_util       = require "quickimpl.treesitter"
local FuncNode      = require "quickimpl.treesitter.node.func_node"
local TemplateNode  = require "quickimpl.treesitter.node.template_node"
local Type          = require "quickimpl.treesitter.node.cpp_type"

-------------------------------------------------------------------------------

local has_child_class = function(node)
  for child in node:iter_children() do
    if child:type() == Type.CLASS_SPECIFIER then return true end
  end
  return false
end

local is_valid_class_node = function(node)
  if node == nil then return false end
  local valid_type = {
    [Type.TEMPLATE_DECLARATION] = has_child_class,
    [Type.CLASS_SPECIFIER] = function() return true end
  }
  local type = node:type()
  return valid_type[type] ~= nil and valid_type[type](node)
end

-------------------------------------------------------------------------------

---@class ClassNode
---@field node TSNode
---@field bufnr integer
---@field template (TemplateNode|nil)
local ClassNode = {}
ClassNode.__index = ClassNode

-------------------------------------------------------------------------------

ClassNode.new = function(node, bufnr)
  local self = setmetatable({}, ClassNode)
  if not is_valid_class_node(node) then return nil end
  self.node = node
  self.bufnr = bufnr or 0

  local parent = ts_util.search_parent_with_type(Type.TEMPLATE_DECLARATION, node, 1)
  self.template = parent and TemplateNode.new(parent, bufnr) or TemplateNode.new(node, bufnr)

  if self.template then
    self.node = assert(ts_util.first_child_with_type(
      Type.CLASS_SPECIFIER,
      self.template:get_node()))
  end

  return self
end

---@retur string
function ClassNode:get_identifier()
  local identifer = ts_util.first_child_with_type(Type.TYPE_IDENTIFIER, self.node)
  if identifer == nil then return '' end
  return ts.get_node_text(identifer, self.bufnr)
end

---@return TSNode
function ClassNode:get_node()
  return self.node
end

---@return (TemplateNode|nil)
function ClassNode:get_template()
  return self.template
end

function ClassNode:iter_func_decl()
  local function_declarations = {}
  local declaration_list = ts_util.first_child_with_type(
    Type.FIELD_DECLARATION_LIST,
    self.node)
  if declaration_list == nil then return ipairs({}) end
  for child in declaration_list:iter_children() do
    local func_node = FuncNode.new(child, bufnr)
    if func_node then
      table.insert(function_declarations, child)
    end
  end
  return ipairs(function_declarations and function_declarations or {})
end

-------------------------------------------------------------------------------

return ClassNode
