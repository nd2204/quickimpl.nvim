local ts          = vim.treesitter
local ts_util     = require "quickimpl.treesitter"

--------------------------------------------------------------------------------

local FuncDecl  = require "quickimpl.treesitter.declaration.func_decl"
local ClassDecl = require "quickimpl.treesitter.declaration.class_decl"
local declaration_classes = { FuncDecl, ClassDecl }
--- redefine DeclFactory because of dependencies loop
local DeclFactory = function(node)
  local decl
  for _, declaration in pairs(declaration_classes) do
    decl = declaration.new(node)
    if decl then return decl end
  end
  return nil
end

-------------------------------------------------------------------------------

---@class NamespaceDeclaration
---@field node TSNode
---@field name string
local NamespaceDeclaration = {}
NamespaceDeclaration.__index = NamespaceDeclaration

-------------------------------------------------------------------------------

NamespaceDeclaration.new = function(node)
  local self = setmetatable({}, NamespaceDeclaration)
  if not node or node:type() ~= 'namespace_definition' then return nil end
  self.node = node
  self.name = ts.get_node_text(
    assert(ts_util.first_child_with_type(
      'namespace_identifier',
      self.node
    )),
    0
  )
  return self
end

function NamespaceDeclaration:get_node()
  return self.node
end

function NamespaceDeclaration:define()
  local declaration = ""
  local declaration_list = ts_util.first_child_with_type(
    'declaration_list',
    self.node
  )

  if declaration_list then
    for child in declaration_list:iter_children() do
      local decl = DeclFactory(child)
      if decl then 
        for _, def in ipairs(decl:define()) do
          declaration = declaration..def
        end
      end
    end
  end
  
  return {
    string.format("namespace %s {\n", self.name)
    ..declaration
    .."\n}\n\n",
  }
end

function NamespaceDeclaration:get_type()
  return 'namespace'
end

-------------------------------------------------------------------------------

return NamespaceDeclaration
