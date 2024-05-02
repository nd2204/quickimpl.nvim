local config = require "quickimpl.config"
local ClassNode = require "quickimpl.treesitter.node.class_node"
local FuncNode = require "quickimpl.treesitter.node.func_node"

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
---@field class string
---@field template string
---@field funcNode FuncNode | nil
local FunctionDeclaration = {}
FunctionDeclaration.__index = FunctionDeclaration

-------------------------------------------------------------------------------

FunctionDeclaration.new = function(node)
  local self = setmetatable({}, FunctionDeclaration)

  self.funcNode = FuncNode.new(node)
  if not self.funcNode then return nil end

  self.type = self.funcNode:get_type()
  self.scs = self.funcNode:get_storage_class_specifier()
  self.declarator = self.funcNode:get_declarator()

  local template_function_node = self.funcNode:get_template()
  self.template = template_function_node
    and 'template'..template_function_node:get_param_list()..'\n'
    or ''

  self.class = ''
  local class_node = ClassNode.new(self.funcNode:get_parent_class())
  if class_node then
    local template_class_node = class_node:get_template()
    self.class = self.class..class_node:get_identifier()
    if template_class_node then
      self.class = self.class..template_class_node:get_arg_list()
    end
    self.class = self.class..'::'
  end
  return self
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

function FunctionDeclaration:get_type()
  if self.class ~= '' then
    return 'method'
  end
  return 'function'
end

-------------------------------------------------------------------------------

return FunctionDeclaration
