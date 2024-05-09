local DeclFactory = require "quickimpl.treesitter.declaration.decl_factory"
local ts_util     = require "quickimpl.treesitter"
local ts          = vim.treesitter

-------------------------------------------------------------------------------

---@class Declarations
---@field node TSNode
---@field declarations table<ClassDeclaration|FunctionDeclaration>
---@field defined_node table<TSNode, table<string>>
local Declarations = {}
Declarations.__index = Declarations

-------------------------------------------------------------------------------

Declarations.new = function(root)
  local self = setmetatable({}, Declarations)
  self.node = root
  self.declarations = {}
  self.defined_node = {}
  self:define_all(self.node)
  return self
end

function Declarations:define_root(node)
  if node == nil or not node:named() then return end
  for child in node:iter_children() do
    local decl = DeclFactory(child)
    if decl then self.defined_node[child] = decl:define() end
    self:define_root(child)
  end
end

function Declarations:define_all(node)
  if node == nil or not node:named() then return end
  for child in node:iter_children() do
    local decl = DeclFactory(child)
    if decl then self.defined_node[child] = decl:define() end
    self:define_root(child)
  end
end

function Declarations:add(declaration)
  table.insert(self.defined_node, declaration)
end

function Declarations:get_defined_node()
  return self.defined_node
end

function Declarations:defined(declaration)
  for _, decl in pairs(self.defined_node) do
    if decl:get_declaration() == declaration then return true end
  end
  return false
end

-------------------------------------------------------------------------------

return Declarations
