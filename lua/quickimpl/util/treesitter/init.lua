local ts = vim.treesitter

local M = {}

M.first_parent_with_type = function(type ,node)
  while node ~= nil and node:type() ~= type do
    node = node:parent()
  end
  return node
end

M.first_child_with_type = function(type, node)
  for child in node:iter_children() do
    if child:type() == type then
      return child
    end
  end
  return nil
end

M.first_child_with_types = function(types, node)
  for child in node:iter_children() do
    for i = 1, #types do
      if child:type() == types[i] then
        return child
      end
    end
  end
  return nil
end

M.get_all_child = function(node)
  local children = {}
  for child in node:iter_children() do
    children[child:type()] = child
  end
  return children
end

M.get_namespace_node = function(node)
  while node ~= nil and node:type() ~= 'namespace_definition' do
    node = node:parent()
  end
  return node
end

---Check if the declaration is a function declaration
M.has_child_func_decl = function(node)
  for child in node:iter_children() do
    if child:type() == 'function_declarator' then return true end
  end
  return false
end

M.has_child_class = function(node)
  for child in node:iter_children() do
    if child:type() == 'class_specifier' then return true end
  end
  return false
end

M.is_valid_func_node = function(node)
  if node == nil then return false end
  local valid_type = {
    ['template_declaration'] = function(_node)
      for child in _node:iter_children() do
        if M.has_child_func_decl(child) then return true end
      end
    end,
    ['field_declaration'] = M.has_child_func_decl,
    ['declaration'] = M.has_child_func_decl,
  }
  local type = node:type()
  return valid_type[type] ~= nil and valid_type[type](node)
end

M.is_valid_class_node = function(node)
  if node == nil then return false end
  local valid_type = {
    ['template_declaration'] = M.has_child_class,
    ['class_specifier'] = function() return true end
  }
  local type = node:type()
  return valid_type[type] ~= nil and valid_type[type](node)
end

M.highlight_node = function(node, ns)
  assert(ns ~= nil, "ns must not be nil")
  local lnum, col, end_lnum, end_col = node:range()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(0, ns, lnum, col, {
    end_row = end_lnum,
    end_col = math.max(0, end_col),
    hl_group = 'Visual',
  })
end

return M
