local ClassNode = require "quickimpl.treesitter.node.class_node"
local FuncDecl = require "quickimpl.treesitter.declaration.func_decl"

-------------------------------------------------------------------------------

---@class ClassDeclaration
---@field classNode ClassNode | nil
---@field function_list table<FunctionDeclaration>
local ClassDeclaration = {}
ClassDeclaration.__index = ClassDeclaration

-------------------------------------------------------------------------------

ClassDeclaration.new = function(node)
  local self = setmetatable({}, ClassDeclaration)

  self.classNode = ClassNode.new(node)
  if not self.classNode then return nil end

  self.function_list = {}
  local func_decl
  for _, _node in self.classNode:iter_func_decl() do
    func_decl = FuncDecl.new(_node)
    if func_decl then
      table.insert(self.function_list, func_decl)
    end
  end
  return self
end

---Return a list of defined function in a class
---@return table
function ClassDeclaration:define()
  local definitions_list = {}
  for _, func_decl in pairs(self.function_list) do
    table.insert(definitions_list, func_decl:define()[1])
  end
  return definitions_list
end

function ClassDeclaration:get_declaration()
  local definitions_list = {}
  for _, func_decl in pairs(self.function_list) do
    table.insert(definitions_list, func_decl:get_declaration()[1])
  end
  return definitions_list
end

---@return TSNode
function ClassDeclaration:get_node()
  local template_node = self.classNode:get_template()
  if  template_node then
    return template_node:get_node()
  end
  return self.classNode:get_node()
end

---@return string
function ClassDeclaration:get_type()
  return "class"
end

-------------------------------------------------------------------------------

return ClassDeclaration
