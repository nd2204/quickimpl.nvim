local ts = vim.treesitter

local M = {}

M.is_class_specifier = function(node)
  return node:type() == 'class_specifier'
end

M.is_template_declaration = function(node)
  return node:type() == 'template_declaration'
end

M.is_declaration = function(node)
  local accepted_declaration = {
    ['declaration'] = true,
    ['field_declaration'] = true,
  }
  return accepted_declaration[node:type()]
end

M.get_namespace_node = function(node)
  while node ~= nil and node:type() ~= 'namespace_definition' do
    node = node:parent()
  end
  return node
end

M.is_template_class_declaration = function(node)
  if not M.is_template_declaration(node) then return false end
  for child in node:iter_children() do
    if M.is_class_specifier(child) then return true end
  end
  return false
end

M.get_cursor_class_or_function = function()
  local node = ts.get_node()
  while node ~= nil and not (M.is_function_declaration(node)
    or M.is_class_specifier(node)
    or M.is_template_class_declaration(node)
    or M.is_template_function_declaration(node))
  do
    node = node:parent()
  end
  return node
end

---Check if the declaration is a function declaration
M.is_function_declaration = function(node)
  if not M.is_declaration(node) then return false end
  for child in node:iter_children() do
    if child:type() == 'function_declarator' then return true end
  end
  return false
end

M.is_template_function_declaration = function(node)
  if not M.is_template_declaration(node) then return false end
  for child in node:iter_children() do
    if M.is_function_declaration(child) then return true end
  end
  return false
end

M.get_function_parent_class = function(node)
  for _ = 1, 2 do
    node = node:parent()
    if node == nil then return node end
    if M.is_class_specifier(node) then
      return node
    end
  end
  return nil
end

M.get_class_name = function(node)
  if not M.is_class_specifier(node) then
    return ''
  end
  for child in node:iter_children() do
    if child:type() == 'type_identifier' then
      return ts.get_node_text(child, 0)
    end
  end
  return ''
end

return M
