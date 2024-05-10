local ts_util = require "quickimpl.treesitter"
local TemplateNode = require "quickimpl.treesitter.node.template_node"
local ts = vim.treesitter
local Type = require "quickimpl.treesitter.node.cpp_type"

-------------------------------------------------------------------------------

---Check if the declaration is a function declaration
local function has_child_func_decl(node)
  if not node then return false end
  -- for child in node:iter_children() do
  --   if child:type() == Type.FUNCTION_DECLARATOR then
  --     return true
  --   end
  -- end
  if ts_util.search_child_with_type(Type.FUNCTION_DECLARATOR, node, 2) then
    return true
  end
  return false
end

local is_pure_virtual = function(node)
  for child in node:iter_children() do
    local type = child:type()
    if type == Type.NUMBER_LITERAL
      or type == Type.PURE_VIRTUAL_CLAUSE
    then return true end
  end
  return false
end

local is_valid_func_node = function(node)
  if node == nil then return false end
  local type = node:type()
  if type == Type.TEMPLATE_DECLARATION or type == Type.FRIEND_DECLARATION then
    for child in node:iter_children() do
      if has_child_func_decl(child) then return true end
    end
  end
  if type == Type.FIELD_DECLARATION or type == Type.DECLARATION or type == Type.FUNCTION_DEFINITION then
    return has_child_func_decl(node) and not is_pure_virtual(node)
  end
  return false
end

-------------------------------------------------------------------------------

---@class FuncNode
---@field parent_class (TSNode|nil)
---@field template (TemplateNode|nil)
---@field children (TSNode|nil)
---@field node (TSNode)
---@field friend (TSNode)
---@field bufnr integer
local FuncNode = {}
FuncNode.__index = FuncNode

-------------------------------------------------------------------------------

FuncNode.new = function(node, bufnr)
  local self = setmetatable({}, FuncNode)
  if not is_valid_func_node(node) then return nil end
  self.node = node
  self.bufnr = bufnr or 0

  --- init template node
  local parent = ts_util.search_parent_with_type(Type.TEMPLATE_DECLARATION, node, 2)
  self.template = parent and TemplateNode.new(parent, bufnr) or TemplateNode.new(node, bufnr)

  --- check if node is a template node if true then find
  --- the actual function node and reassign the node field
  if self.template then
    self.node = assert(ts_util.first_child_with_types(
      {
        Type.DECLARATION,
        Type.FIELD_DECLARATION,
        Type.FRIEND_DECLARATION,
        Type.FUNCTION_DEFINITION,
      },
      self.template:get_node()))
  end

  --- do the same if the node is a friend node
  if self.node:type() == Type.FRIEND_DECLARATION
       or node:type() == Type.FRIEND_DECLARATION
  then
    self.friend = self.node
    self.node = assert(ts_util.first_child_with_types(
      {Type.DECLARATION, Type.FIELD_DECLARATION},
      self.node))
  end

  --- don't assign a class to the function if it is a friend
  if not ts_util.first_parent_with_type(Type.FRIEND_DECLARATION, self.node) then
    self.parent_class = ts_util.first_parent_with_type(Type.CLASS_SPECIFIER, self.node)
  end

  self.children = ts_util.get_all_child(self.node)
  return self
end

---@return TSNode | nil
function FuncNode:get_parent_class()
  return self.parent_class
end

---@return (TemplateNode|nil)
function FuncNode:get_template()
  return self.template
end

---@return string
function FuncNode:get_type()
  local type = ts_util.first_child_with_types({
    Type.TYPE_IDENTIFIER,
    Type.PRIMITIVE_TYPE,
    Type.QUALIFIED_IDENTIFIER,
  }, self.node)
  local type_str = type and ts.get_node_text(type, self.bufnr)..' ' or ''
  return type_str
end

---@return string
function FuncNode:get_storage_class_specifier()
  local scs_node = self.children[Type.STORAGE_CLASS_SPECIFIER]
  if not scs_node then return '' end
  local scs = ts.get_node_text(scs_node, self.bufnr)..' '
  if string.gsub(scs, "%s+", "") == 'static' then
    self.scs = ''
  end
  return scs
end

---@return string
function FuncNode:get_declarator()
  local declarator_node = self.children[Type.FUNCTION_DECLARATOR]
  if not declarator_node then return '' end
  return ts.get_node_text(declarator_node, self.bufnr)..' '
end

---@return TSNode
function FuncNode:get_node()
  return self.node
end

---@return boolean
function FuncNode:has_friend_node()
  return self.friend and true or false
end

-------------------------------------------------------------------------------

return FuncNode
