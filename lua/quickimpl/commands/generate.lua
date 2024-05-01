local api = vim.api
local ts = vim.treesitter
local ts_util = require('quickimpl.util.treesitter')
local FuncDecl = require("quickimpl.util.treesitter.declaration.func_decl")
local ClassDecl = require("quickimpl.util.treesitter.declaration.class_decl")

local M = {}
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

local get_cursor = function()
  local node = ts.get_node()
  while node ~= nil and not (ts_util.is_valid_func_node(node) 
    or ts_util.is_valid_class_node(node))
  do
    node = node:parent()
  end
  return node
end

--------------------------------------------------------------------------------
--- Modules
--------------------------------------------------------------------------------
function DeclarationFactory(node)
  local class_constructors_callable = {
    FuncDecl.new,
    ClassDecl.new,
  }
  local decl
  for i = 1, #class_constructors_callable do
    decl = class_constructors_callable[i](node)
    if decl then return decl end
  end
  return nil
end

M.callback = function(params)
  ---Get full file path of a buffer
  local path = api.nvim_buf_get_name(0)

  ---get parser
  local parser = ts.get_parser()
  local lang = parser:lang()
  vim.print("Detected lang: " .. lang)
  -- local root = parser:parse()[1]:root()

  local group = vim.api.nvim_create_augroup('quickimpl/treesitter', {})
  local ns = vim.api.nvim_create_namespace('quickimpl-highlight')

  local cursor_node = get_cursor()
  local decl = DeclarationFactory(cursor_node)
  if not decl then return end
  ts_util.highlight_node(decl:get_node(), ns)
  vim.print(decl:define())

  -- local id = vim.api.nvim_create_autocmd('CursorMoved', {
  --   group = group,
  --   buffer = 0,
  --   callback = function()
  --     cursor_node = get_cursor()
  --     decl = DeclarationFactory(cursor_node)
  --     if not decl then return end
  --     ts_util.highlight_node(decl:get_node(), ns)
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
  --     vim.print(decl:define())
  --   end
  -- })
end

return M
