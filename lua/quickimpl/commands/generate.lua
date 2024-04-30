local M = {}

local api = vim.api
local ts = vim.treesitter
local ts_util = require('quickimpl.treesitter')
local FunctionDeclaration = require("quickimpl.util.treesitter.function")
ts_util.highlight_node = require("quickimpl.util.treesitter.node").highlight_node
-- local uv = vim.loop

--------------------------------------------------------------------------------
--- Class Properties
--------------------------------------------------------------------------------
M.name = 'QIGenerate'

M.opts = {
  bang = false,
  bar = false,
  nargs = 0,
  addr = 'other',
  -- complete = function()
  --   return supported_args
  -- end,
}

--------------------------------------------------------------------------------
--- Local functions
--------------------------------------------------------------------------------
function M.callback(params)
  ---Get full file path of a buffer
  local path = api.nvim_buf_get_name(0)

  ---get parser
  local parser = ts.get_parser()
  local root = parser:parse()[1]:root()

  local group = vim.api.nvim_create_augroup('quickimpl/treesitter', {})
  local ns = vim.api.nvim_create_namespace('quickimpl-highlight')
  local cursor_node = ts_util.get_cursor_class_or_function()
  if cursor_node then
    ts_util.highlight_node(cursor_node, ns)
  end
  local function_declaration = FunctionDeclaration.new(cursor_node)
  vim.print(function_declaration:define())

  -- local id = vim.api.nvim_create_autocmd('CursorMoved', {
  --   group = group,
  --   buffer = 0,
  --   callback = function()
  --     cursor_node = ts_util.get_cursor_class_or_function()
  --     if cursor_node == nil then return end
  --     ts_util.highlight_node(cursor_node, ns)
  --     -- print(cursor_node:type())
  --   end,
  -- })

  -- vim.api.nvim_buf_set_keymap(0, "n", "<ESC>", "",{
  --   desc = "Cancel selection",
  --   callback = function()
  --     vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  --     vim.api.nvim_del_autocmd(id)
  --     vim.api.nvim_buf_del_keymap(0, "n", "<ESC>")
  --   end
  -- })

  -- vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "",{
  --   desc = "Confirm declarable selection",
  --   callback = function()
  --     if cursor_node == nil then return end

  --     vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  --     vim.api.nvim_del_autocmd(id)
  --     vim.api.nvim_buf_del_keymap(0, "n", "<CR>")
  --   end
  -- })
  end

  return M
