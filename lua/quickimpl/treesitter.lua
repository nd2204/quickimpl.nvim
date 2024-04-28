local ts = vim.treesitter

local M = {}

--- abstract class TSQuery
TSQuery = {}
TSQuery.__index = TSQuery

function TSQuery:count()
  return self.num_captures_id
end

function TSQuery:get_query_capture(node, lang)
  local parsed = ts.query.parse(lang, self.query_string)
  local captured = {}
  local count = 0
  local temp = {}
  for id, n, _ in parsed:iter_captures(node, 0, node:start()) do
    id = assert(id, "ERROR: capture id is nil. Check the query_string")
    temp[parsed.captures[id]] = n
    count = count + 1
    if count >= self.num_captures_id then
      table.insert(captured, temp)
      temp = {}
      count = 0
    end
  end
  return captured
end

--- Concrete implementations of TSQuery subclasses
FunctionQuery = {}
FunctionQuery.__index = FunctionQuery
setmetatable(FunctionQuery, TSQuery)

function FunctionQuery.new(type, func_decl)
  local instance = setmetatable({}, FunctionQuery)
  instance.num_captures_id = 2
  instance.query_string = string.format([[ 
    (declaration
      type: [(type_identifier) (primitive_type)] @%s
      declarator: (function_declarator) @%s
      !default_value)
  ]], type, func_decl)
  return instance
end

MethodQuery = {}
MethodQuery.__index = MethodQuery
setmetatable(MethodQuery, TSQuery)

function MethodQuery.new(type, func_decl)
  local instance = setmetatable({}, MethodQuery)
  instance.num_captures_id = 2
  instance.query_string = string.format([[ 
    (field_declaration
      type: [(type_identifier) (primitive_type)] @%s
      declarator: (function_declarator) @%s
      !default_value)
  ]], type, func_decl)
  return instance
end

NamespaceQuery = {}
NamespaceQuery.__index = NamespaceQuery
setmetatable(NamespaceQuery, TSQuery)

function NamespaceQuery.new(ns_name, ns_decl_list, ns)
  ns_name = ns_name and ns_name or 'ns_name'
  ns_decl_list = ns_decl_list and ns_decl_list or 'ns_decl_list'
  ns = ns and ns or 'ns'
  local instance = setmetatable({}, NamespaceQuery)
  instance.num_captures_id = 3
  instance.query_string = string.format([[
    (namespace_definition
      name: (namespace_identifier) @%s
      body: (declaration_list) @%s
    ) @%s
    ]], ns_name, ns_decl_list, ns)
  return instance
end

ConstructorQuery = {}
ConstructorQuery.__index = ConstructorQuery
setmetatable(ConstructorQuery, TSQuery)

function ConstructorQuery.new(decl)
  local instance = setmetatable({}, ConstructorQuery)
  instance.num_captures_id = 3
  instance.query_string = string.format([[
      (declaration
        !type
        declarator: (function_declarator) @%s)
    ]], decl)
  return instance
end

TemplateFunctionQuery = {}
TemplateFunctionQuery.__index = TemplateFunctionQuery
setmetatable(TemplateFunctionQuery, TSQuery)

function TemplateFunctionQuery.new(template_params, type, decl, template)
  local instance = setmetatable({}, TemplateFunctionQuery)
  instance.num_captures_id = 4
  instance.query_string = string.format([[
      (template_declaration
        parameters: (template_parameter_list) @%s
        (declaration
          type: [(primitive_type) (type_identifier)] @type
          declarator: (function_declarator) @decl
          !default_value
        )
      ) @template_function
    ]], template_params, type, decl, template)
  return instance
end

---

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

function M.is_declaration(node)
  local names = { "field_declaration", "declaration" }
  for i = 1, #names do
    if names[i] == node:type() then
      return true
    end
  end
  return false
end

function M.get_cursor_declaration()
  local node = ts.get_node()
  while node ~= nil and not M.is_declaration(node) do
    node = node:parent()
  end
  return node
end

function M.get_cursor_class()
  local node = ts.get_node()
  while node ~= nil and node:type() ~= 'class_specifier' do
    node = node:parent()
  end
  return node
end

---@param node (TSNode)
---@param lang (string)
---@param query (string)
---@return table<string, TSNode>
function M.get_query_capture(node, lang, query)
  local parsed = ts.query.parse(lang, query)
  local captured = {}
  for id, n, _ in parsed:iter_captures(node, 0, node:start()) do
    id = assert(id, "ERROR: capture id is nil. Check the captures_name variable")
    table.insert(captured, id, {
      [parsed.captures[id]] = n
    })
    -- captured[parsed.captures[id]] = _node
    -- vim.print(id ,ts.get_node_text(n, 0))
  end
  return captured
end

M.debug = {}

---@param node (TSNode)
function M.debug.print_node_sexpr(node)
  local sexpr = assert(node, 'node is nil'):sexpr()
  print(sexpr)
end

return M
