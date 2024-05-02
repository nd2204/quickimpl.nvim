local M = {}

--------------------------------------------------------------------------------

---Search for parent node with matching type
---@return (TSNode|nil)
---@param type string
---@param node (TSNode|nil)
M.first_parent_with_type = function(type ,node)
  assert(node)
  while node ~= nil and node:type() ~= type do
    node = node:parent()
  end
  return node
end

---get parent node if it has matching type
---@return (TSNode|nil)
---@param type string
---@param node (TSNode|nil)
---@param height (integer)
M.search_parent_with_type = function(type ,node, height)
  assert(node)
  for _ = 1, height do
    node = node:parent()
    if node ~= nil and node:type() == type then
      return node
    end
  end
  return nil
end

---Search for children node with matching type
---@return (TSNode|nil)
---@param type string
---@param node (TSNode|nil)
M.first_child_with_type = function(type, node)
  if not node then return nil end
  for child in node:iter_children() do
    if child:type() == type then
      return child
    end
  end
  return nil
end

---search for children node with matching list of type
---@return (TSNode|nil)
---@param types string[]
---@param node (TSNode|nil)
M.first_child_with_types = function(types, node)
  assert(node)
  for child in node:iter_children() do
    if vim.tbl_contains(types, child:type()) then
      return child
    end
    -- for i = 1, #types do
    --   if child:type() == types[i] then
    --     return child
    --   end
    -- end
  end
  return nil
end

---recursively searching for all children in associate with their type
---@return table<string,(TSNode|nil)>
---@param node (TSNode|nil)
M.get_all_child = function(node)
  assert(node)
  local children = {}
  if not node then return children end
  for child in node:iter_children() do
    children[child:type()] = child
  end
  return children
end

M.highlight_node = function(node, ns, text)
  assert(ns ~= nil, "ns must not be nil")
  local lnum, col, end_lnum, end_col = node:range()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(0, ns, lnum, col, {
    end_row = end_lnum,
    end_col = math.max(0, end_col),
    hl_group = 'Visual',
    virt_text = { { " "..text, "Yellow" } },
  })
end

--------------------------------------------------------------------------------

return M
