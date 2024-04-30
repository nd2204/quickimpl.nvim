local ts = vim.treesitter
local ts_util = require("quickimpl.treesitter")

local blacklisted_scs = {
  ['static'] = true,
}

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
local FunctionDeclaration = {}
FunctionDeclaration.__index = FunctionDeclaration

FunctionDeclaration.new = function(node)
  local instance = setmetatable({}, FunctionDeclaration)
  instance.type = ''
  instance.scs = ''
  instance.declarator = ''
  instance.template = ''
  instance.class = ''
  local class_node = ts_util.get_function_parent_class(node)
  if class_node then
    instance:set_class(ts_util.get_class_name(class_node))
  end
  if ts_util.is_template_function_declaration(node) then
    for child in node:iter_children() do
      if child:type() == 'template_parameter_list' then
        instance.template = "template"..ts.get_node_text(child, 0)..'\n'
      end
      if ts_util.is_function_declaration(child) then
        node = child
      end
    end
  elseif not ts_util.is_function_declaration(node) then
    return nil
  end
  for child in node:iter_children() do
    local type = child:type()
    if type == 'function_declarator' then
      instance.declarator = ts.get_node_text(child, 0)..' '
    end
    if type == 'storage_class_specifer' then
      local node_text = ts.get_node_text(child, 0)
      if not blacklisted_scs[node_text] then
        instance.scs = node_text..' '
      end
    end
    if type == 'primitive_type' or type == 'type_identifier' then
      instance.type = ts.get_node_text(child, 0)..' '
    end
  end
  return instance
end

---@param class string
function FunctionDeclaration:set_class(class)
  self.class = class..'::'
end

function FunctionDeclaration:define(brace_pattern)
  brace_pattern = brace_pattern or "{\n\t\n}\n\n"
  return string.format(
    [[%s%s%s%s%s%s]],
    self.template,
    self.scs,
    self.type,
    self.class,
    self.declarator,
    brace_pattern
  )
end

return FunctionDeclaration
