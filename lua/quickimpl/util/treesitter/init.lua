local ts = vim.treesitter
local M = {}

--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------

return M
