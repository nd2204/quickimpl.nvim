local ClassNode = require "quickimpl.util.treesitter.node.class_node"
local FuncDecl = require "quickimpl.util.treesitter.declaration.func_decl"

---@class ClassDeclaration
---@field classNode ClassNode | nil
---@field function_list table<FunctionDeclaration>
local ClassDeclaration = {}
ClassDeclaration.__index = ClassDeclaration

ClassDeclaration.new = function(node)
  local instance = setmetatable({}, ClassDeclaration)

  instance.classNode = ClassNode.new(node)
  if not instance.classNode then return nil end

  instance.function_list = {}

  local func_decl
  for _, _node in instance.classNode:iter_func_decl() do
    func_decl = FuncDecl.new(_node)
    if func_decl then
      table.insert(instance.function_list, func_decl)
    end
  end
  return instance
end

---Return a list of defined function in a class
---@return table
function ClassDeclaration:define()
  local definitions_list = {}
  for _, v in pairs(self.function_list) do
    table.insert(definitions_list, v:define())
  end
  return definitions_list
end

function ClassDeclaration:get_node()
  return self.classNode:get_node()
end

return ClassDeclaration
