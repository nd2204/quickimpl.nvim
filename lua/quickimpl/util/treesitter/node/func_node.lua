local ts_util = require("quickimpl.util.treesitter")
local ts = vim.treesitter

---@class FuncNode : Node
---@field parent_class (TSNode|nil)
---@field template_params (TSNode|nil)
---@field children (TSNode|nil)
local FuncNode = {}
FuncNode.__index = FuncNode
setmetatable(FuncNode, Node)

FuncNode.new = function(node)
  local instance = setmetatable({}, FuncNode)
  if not ts_util.is_valid_func_node(node) then return nil end
  instance.node = node
  if node:type() == 'template_declaration' then
    instance.node = assert(ts_util.first_child_with_types(
      {'declaration', 'field_declaration'},
      node))
    instance.template_params = ts_util.first_child_with_type(
      'template_parameter_list',
      node
    )
  end
  instance.parent_class = ts_util.first_parent_with_type('class_specifier', node)
  instance.children = ts_util.get_all_child(instance.node)
  return instance
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

return FuncNode
