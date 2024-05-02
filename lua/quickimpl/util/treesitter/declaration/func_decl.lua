local config = require "quickimpl.config"
local ClassNode = require "quickimpl.util.treesitter.node.class_node"
local FuncNode = require "quickimpl.util.treesitter.node.func_node"

-------------------------------------------------------------------------------

---@class FunctionDeclaration
---return type of the function. empty if it is a constructor or destructor
---Example: int, void, float
---@field type string
---storage class specifier of the function.
---Example: static, extern
---@field scs string
---the identifer (name) and parameter list of the function.
---@field declarator string
---the template declaration of the function.
---@field template string
---@field funcNode FuncNode | nil
local FunctionDeclaration = {}
FunctionDeclaration.__index = FunctionDeclaration

-------------------------------------------------------------------------------

FunctionDeclaration.new = function(node)
  local instance = setmetatable({}, FunctionDeclaration)

  instance.funcNode = FuncNode.new(node)
  if not instance.funcNode then return nil end

  instance.type = instance.funcNode:get_type()
  instance.scs = instance.funcNode:get_storage_class_specifier()
  if string.gsub(instance.scs, "%s+", "") == 'static' then
    instance.scs = ''
  end
  instance.declarator = instance.funcNode:get_declarator()
  instance.template = instance.funcNode:get_template_params()

  instance.class = ''
  local class_node = ClassNode.new(instance.funcNode:get_parent_class())
  if class_node then
    instance:set_class(class_node:get_identifier())
  end
  return instance
end

---@param class string
function FunctionDeclaration:set_class(class)
  self.class = class..'::'
end

---@return table<string>
function FunctionDeclaration:define()
  local brace_pattern = config.get_key_value('brace_pattern')
  return {
    string.format("%s%s%s%s%s%s",
      self.template,
      self.scs,
      self.type,
      self.class,
      self.declarator,
      brace_pattern
    )
  }
end

---@return TSNode
function FunctionDeclaration:get_node()
  return self.funcNode:get_node()
end

-------------------------------------------------------------------------------

return FunctionDeclaration
