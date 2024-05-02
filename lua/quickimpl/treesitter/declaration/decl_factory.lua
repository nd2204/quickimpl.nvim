local FuncDecl  = require "quickimpl.treesitter.declaration.func_decl"
local ClassDecl = require "quickimpl.treesitter.declaration.class_decl"
local NsDecl    = require "quickimpl.treesitter.declaration.ns_decl"

--------------------------------------------------------------------------------

local declaration_classes = { FuncDecl, ClassDecl, NsDecl }
local DeclarationFactory = function(node)
  local decl
  for _, declaration in pairs(declaration_classes) do
    decl = declaration.new(node)
    if decl then return decl end
  end
  return nil
end

--------------------------------------------------------------------------------

return DeclarationFactory
