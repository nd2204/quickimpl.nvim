local M = {}

--------------------------------------------------------------------------------
--- Private Properties
--------------------------------------------------------------------------------

local default_config = {
  -- add_header_include = true,
  brace_pattern = " {\n\t\n}\n\n",
}

M.config = default_config

--------------------------------------------------------------------------------
--- Local functions
--------------------------------------------------------------------------------

-- local function first_non_nil(...)
--   local n = select('#', ...)
--   for i = 1, n do
--     local value = select(i, ...)
--     if value ~= nil then
--       return value
--     end
--   end
-- end

--------------------------------------------------------------------------------
--- public Methods
--------------------------------------------------------------------------------

function M.setup(opts)
  for k, _ in pairs(M.config) do
    if opts[k] ~= nil then
      M.config[k] = opts[k]
    end
  end

  -- vim.g.generate_add_header_include = first_non_nil(
  --   opts.add_header_include,
  --   opts.add_header_include
  -- )
end

function M.get_default_config()
  return default_config
end

function M.get_config()
  return M.config
end

function M.get_default_key_value(key)
  return default_config[key]
end

function M.get_key_value(key)
  return M.config[key]
end

function M.set_key_value(key, value)
  M.config[key] = value
end

---@return (string) OS
function M.getOS()
  if vim.fn.has("win32") or vim.fn.has("win64") then
    return "Window"
  else
    return "Linux"
  end
end

--------------------------------------------------------------------------------

return M
