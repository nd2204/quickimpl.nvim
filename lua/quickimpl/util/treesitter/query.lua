local ts = vim.treesitter
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

function MethodQuery.new(opts)
  local instance = setmetatable({}, MethodQuery)
  instance.num_captures_id = 2
  instance.query_string = string.format([[ 
    (field_declaration
      type: [(type_identifier) (primitive_type)] @%s
      declarator: (function_declarator) @%s
      !default_value)
  ]], opts.type, opts.func_decl)
  return instance
end

NamespaceQuery = {}
NamespaceQuery.__index = NamespaceQuery
setmetatable(NamespaceQuery, TSQuery)

function NamespaceQuery.new(opts)
  opts.ns_name = opts.ns_name and opts.ns_name or 'ns_name'
  opts.ns_decl_list = opts.ns_decl_list and opts.ns_decl_list or 'ns_decl_list'
  opts.ns = opts.ns and opts.ns or 'ns'
  local instance = setmetatable({}, NamespaceQuery)
  instance.num_captures_id = 3
  instance.query_string = string.format([[
    (namespace_definition
      name: (namespace_identifier) @%s
      body: (declaration_list) @%s
    ) @%s
    ]], opts.ns_name, opts.ns_decl_list, opts.ns)
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
        parameters: (template_parameter_list) @template_params
        (declaration
          type: [(primitive_type) (type_identifier)] @type
          declarator: (function_declarator) @decl
          !default_value
        )
      ) @template_function
    ]], template_params, type, decl, template)
  return instance
end
