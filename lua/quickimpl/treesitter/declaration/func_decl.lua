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

FunctionDeclaration.new = function(node, bufnr)
  local self = setmetatable({}, FunctionDeclaration)

  self.funcNode = FuncNode.new(node, bufnr)
  if not self.funcNode then return nil end

  ---assign function template if applicable
  local templ_func_node = self.funcNode:get_template()
  self.template = templ_func_node and templ_func_node:get_template_decl() or ''
  self.class = ''
  ---assign class and class template if applicable
  if not self.funcNode:has_friend_node() then
    local classNode = ClassNode.new(self.funcNode:get_parent_class(), bufnr)
    local templ_class_node = classNode and classNode:get_template() or nil
    if classNode then
      self.class = classNode:get_identifier()
      if templ_class_node then
        self.class = self.class..templ_class_node:get_arg_list()
        self.template = templ_class_node:get_template_decl()..self.template
      end
      self.class = self.class..'::'
    end
  end
  return self
end

---@return table<string>
function FunctionDeclaration:get_declaration()
  return {
    string.format("%s%s%s%s%s",
      self.template,
      self.funcNode:get_storage_class_specifier(),
      self.funcNode:get_type(),
      self.class,
      self.funcNode:get_declarator()
    )
  }
end

---@return table<string>
function FunctionDeclaration:define()
  local brace_pattern = config.get_key_value('brace_pattern')
  return {
    string.format("%s%s%s%s%s%s",
      self.template,
      self.funcNode:get_storage_class_specifier(),
      self.funcNode:get_type(),
      self.class,
      self.funcNode:get_declarator(),
      brace_pattern
    )
  }
end

---@return TSNode
function FunctionDeclaration:get_node()
  local template_node = self.funcNode:get_template()
  if template_node then
    return template_node:get_node()
  end
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
