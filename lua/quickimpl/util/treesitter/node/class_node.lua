local ts = vim.treesitter
local ts_util = require("quickimpl.util.treesitter")
local FuncNode = require "quickimpl.util.treesitter.node.func_node"

-------------------------------------------------------------------------------
local has_child_class = function(node)
  for child in node:iter_children() do
    if child:type() == 'class_specifier' then return true end
  end
  return false
end

local is_valid_class_node = function(node)
  if node == nil then return false end
  local valid_type = {
    ['template_declaration'] = has_child_class,
    ['class_specifier'] = function() return true end
  }
  local type = node:type()
  return valid_type[type] ~= nil and valid_type[type](node)
end

-------------------------------------------------------------------------------

---@class ClassNode
---@field node TSNode
local ClassNode = {}
ClassNode.__index = ClassNode

ClassNode.new = function(node)
  local instance = setmetatable({}, ClassNode)
  if not is_valid_class_node(node) then return nil end
  instance.node = node
  return instance
end

function ClassNode:get_identifier()
  local identifer = ts_util.first_child_with_type('type_identifier', self.node)
  if identifer == nil then return '' end
  return ts.get_node_text(identifer, 0)
end

function ClassNode:get_node()
  return self.node
end

function ClassNode:iter_func_decl()
  local function_declarations = {}
  local declaration_list = ts_util.first_child_with_type(
    'field_declaration_list',
    self.node)
  if declaration_list == nil then return ipairs({}) end
  for child in declaration_list:iter_children() do
    local func_node = FuncNode.new(child)
    if func_node then
      table.insert(function_declarations, child)
    end
  end
  return ipairs(function_declarations and function_declarations or {})
end

return ClassNode
