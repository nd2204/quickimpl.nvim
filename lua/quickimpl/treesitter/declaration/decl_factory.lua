local FuncDecl  = require "quickimpl.treesitter.declaration.func_decl"
local ClassDecl = require "quickimpl.treesitter.declaration.class_decl"

--------------------------------------------------------------------------------

local declaration_classes = { FuncDecl, ClassDecl }
---@return FunctionDeclaration
---| ClassDeclaration
---| nil
local DeclarationFactory = function(node, bufnr)
  local decl
  for _, declaration in pairs(declaration_classes) do
    decl = declaration.new(node, bufnr)
    if decl then return decl end
  end
  return nil
end

--------------------------------------------------------------------------------

return DeclarationFactory
