local ts = vim.treesitter

local M = {}

---@param lang (string) language to use for the query
---@param query (string) query in s-expr syntax
---@return (Query) Parsed
---This function ensure valid api call to parsing the query
function M.parse_query_wrapper(lang, query)
  return ts.query.parse(lang, query)
end

---@param type (string)
---@param parent (TSNode)
---@return TSNode[] matching_childrens
function M.childrens_with_type(type, parent)
  local found = {}
  for child in parent:iter_children() do
    if child:type() == type then
      table.insert(found, child)
    end
  end
  return found
end

---@param node (TSNode)
---@return boolean
function M.is_function_declaration(node)
  if node:type() == 'function_definition' then
    return false
  end
  -- This is needed to understand whether the node is a pure
  -- virtual function, in which case we should return false,
  -- because it should not be implemented. The way a pure
  -- virtual function can be detected is by looking for
  -- 'number_literal' nodes on the same level or under ERROR nodes.
  local numbers = M.childrens_with_type('number_literal', node)
  if #numbers > 0 then
    return false
  end

  for s in {'function_declarator', 'declaration'} do
    if #M.childrens_with_type(s, node) ~= 0 then
      return true
    end
  end

  return false
end

---@param type (string)
---@param parent (TSNode)
---@return (TSNode | nil)
function M.first_child_with_type(type, parent)
  for child in parent:iter_children() do
    if child:type() == type then
      return child
    end
  end
  return nil
end

---@param declarator (TSNode)
---@return (TSNode | nil) identifier if there is matching field name
function M.declarator_identifier(declarator)
  local interesting_names = {
    'field_identifier',
    'identifier',
    'destructor_name',
    'operator_name',
  }

  for i = 1, #interesting_names do
    local name = interesting_names[i]
    local identifier = M.first_child_with_type(name, declarator)
    if identifier ~= nil then
      return identifier
    end
  end

  return nil
end

return M
