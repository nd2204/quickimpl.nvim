local ts = vim.treesitter
local ts_util = require("quickimpl.util.treesitter")

---@class ClassNode
---@field node TSNode
local ClassNode = {}
ClassNode.__index = ClassNode

ClassNode.new = function(node)
  local instance = setmetatable({}, ClassNode)
  if not ts_util.is_valid_class_node(node) then return nil end
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
    if ts_util.is_valid_func_node(child) then
      table.insert(function_declarations, child)
    end
  end
  return ipairs(function_declarations and function_declarations or {})
end

return ClassNode
