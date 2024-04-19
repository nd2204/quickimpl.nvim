if vim.g.loaded_generate ~= nil then
  return
end
vim.g.loaded_generate = true

local M = {}

local api = vim.api
local ts = vim.treesitter
-- local uv = vim.loop

--------------------------------------------------------------------------------
--- Private Properties
--------------------------------------------------------------------------------
local supported_args_value = {
 'define'
}

local opts = {
  bang = false,
  bar = false,
  nargs = 1,
  addr = 'other',
  complete = function()
    return supported_args_value
  end,
}

--------------------------------------------------------------------------------
--- Local functions
--------------------------------------------------------------------------------
local function hasSupportedArgs(arg)
  return supported_args_value[arg] ~= nil
end

local function command_callback(params)
  local path = api.nvim_buf_get_name(0)
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  local header = require('quickimpl.header')
  local source = require('quickimpl.source')
  print(root:sexpr())
  if hasSupportedArgs(params[1]) then
    local namespaces = header.get_declarations(root)
    source.insert_header(path)
    source.define_methods(namespaces)
  end
end

--------------------------------------------------------------------------------
-- REGISTER commands
api.nvim_create_user_command('Quickimpl', command_callback, opts)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- public Methods
--------------------------------------------------------------------------------
M.setup = require('quickimpl.config').setup

return M
