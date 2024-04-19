local config = {}

--------------------------------------------------------------------------------
--- Private Properties
--------------------------------------------------------------------------------

local default_config = {
  add_header_include = true,
  brace_pattern = " {\n\t\n}\n\n",
  lang = ''
}

--------------------------------------------------------------------------------
--- Local functions
--------------------------------------------------------------------------------

local function first_non_nil(...)
  local n = select('#', ...)
  for i = 1, n do
    local value = select(i, ...)
    if value ~= nil then
      return value
    end
  end
end

--------------------------------------------------------------------------------
--- public Methods
--------------------------------------------------------------------------------

function config.setup(opts)
  for k, _ in pairs(default_config) do
    if opts[k] ~= nil then
      default_config[k] = opts[k]
    end
  end

  vim.g.generate_add_header_include = first_non_nil(
    opts.add_header_include,
    opts.add_header_include
  )
end

function config.getDefaultValue(key)
  return default_config[key]
end

---@return (string) OS
function config.getOS()
  if vim.fn.has("win32") or vim.fn.has("win64") then
    return "Window" 
  else
    return "Linux"
  end
end

--------------------------------------------------------------------------------

return config
