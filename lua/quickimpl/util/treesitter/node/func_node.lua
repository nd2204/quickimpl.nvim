local ts_util = require("quickimpl.util.treesitter")
local ts = vim.treesitter

-------------------------------------------------------------------------------

---Check if the declaration is a function declaration
local has_child_func_decl = function(node)
  for child in node:iter_children() do
    if child:type() == 'function_declarator' then return true end
  end
  return false
end

local is_pure_virtual = function(node)
  for child in node:iter_children() do
    if child:type() == 'number_literal' then return true end
  end
  return false
end

local is_valid_func_node = function(node)
  if node == nil then return false end
  local valid_type = {
    ['template_declaration'] = function(_node)
      for child in _node:iter_children() do
        if has_child_func_decl(child) then return true end
      end
    end,
    ['field_declaration'] = function(_node)
      return has_child_func_decl(_node) and not is_pure_virtual(_node)
    end,
    ['declaration'] = function(_node)
      return has_child_func_decl(_node) and not is_pure_virtual(_node)
    end,
    ['friend_declaration'] = function(_node)
      for child in _node:iter_children() do
        if has_child_func_decl(child) then return true end
      end
    end
  }
  local type = node:type()
  return valid_type[type] ~= nil and valid_type[type](node)
end

-------------------------------------------------------------------------------

---@class FuncNode
---@field parent_class (TSNode|nil)
---@field template_params (TSNode|nil)
---@field children (TSNode|nil)
---@field node (TSNode|nil)
local FuncNode = {}
FuncNode.__index = FuncNode

-------------------------------------------------------------------------------

FuncNode.new = function(node)
  local self = setmetatable({}, FuncNode)
  if not is_valid_func_node(node) then return nil end
  self.node = node

  if node:type() == 'template_declaration' then
    self.node = assert(ts_util.first_child_with_types(
      {'declaration', 'field_declaration'},
      node))
    self.template_params = ts_util.first_child_with_type(
      'template_parameter_list',
      node
    )
  end

  if node:type() == 'friend_declaration' then
    self.node = assert(ts_util.first_child_with_types(
      {'declaration', 'field_declaration'},
      node))
  end

  if not ts_util.first_parent_with_type('friend_declaration', self.node) then
    self.parent_class = ts_util.first_parent_with_type('class_specifier', self.node)
  end
  self.children = ts_util.get_all_child(self.node)
  return self
end

---@return TSNode | nil
function FuncNode:get_parent_class()
  return self.parent_class
end

---@return string
function FuncNode:get_template_params()
  if not self.template_params then return '' end
  local template_str = 'template'..ts.get_node_text(self.template_params, 0)..'\n'
  return template_str 
end

---@return string
function FuncNode:get_type()
  local type = self.children['type_identifier']
  type = type and type or self.children['primitive_type']
  local type_str = type and ts.get_node_text(type, 0)..' ' or ''
  return  type_str
end

---@return string
function FuncNode:get_storage_class_specifier()
  local scs_node = self.children['storage_class_specifier']
  if not scs_node then return '' end
  return ts.get_node_text(scs_node, 0)..' '
end

---@return string
function FuncNode:get_declarator()
  local declarator_node = self.children['function_declarator']
  if not declarator_node then return '' end
  return ts.get_node_text(declarator_node, 0)..' '
end

---@return table<string,TSNode>
function FuncNode:get_children()
  return self.children
end

---@return TSNode
function FuncNode:get_node()
  return self.node
end

-------------------------------------------------------------------------------

return FuncNode
