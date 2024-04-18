local config = { }

local default = {
  add_header_include = true,
  brace_pattern = " {\n\t\n}\n\n"
}

local function first_non_nil(...)
  local n = select('#', ...)
  for i = 1, n do
    local value = select(i, ...)
    if value ~= nil then
      return value
    end
  end
end

function config.setup(opts)
  for k, _ in pairs(default) do
    if opts[k] ~= nil then
      default[k] = opts[k] 
    end
  end

  vim.g.generate_add_header_include = first_non_nil(opts.add_header_include, opts.add_header_include)
end

function config.getDefaultValue(key)
  return default[key]
end

return config
