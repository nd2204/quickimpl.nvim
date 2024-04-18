if vim.g.loaded_generate ~= nil then
  return
end
vim.g.loaded_generate = true

local M = {}

local api = vim.api
local ts = vim.treesitter
-- local uv = vim.loop

local function command_callback(params)
  local path = api.nvim_buf_get_name(0)
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  local header = require('quickimpl.header')
  local source = require('quickimpl.source')
  print(root:sexpr())
  if params[1] == 'implementations' then
    local namespaces = header.get_declarations(root)
    source.insert_header(path)
    source.implement_methods(namespaces)
  end
end

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

-- REGISTER commands
api.nvim_create_user_command('Quickimpl', command_callback, opts)

M.setup = require('quickimpl.config').setup

return M
