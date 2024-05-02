local FuncDecl  = require "quickimpl.util.treesitter.declaration.func_decl"
local ClassDecl = require "quickimpl.util.treesitter.declaration.class_decl"
local NsDecl    = require "quickimpl.util.treesitter.declaration.ns_decl"

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
