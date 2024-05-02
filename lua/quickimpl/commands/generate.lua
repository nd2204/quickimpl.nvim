local api = vim.api
local ts = vim.treesitter
local ts_util = require "quickimpl.treesitter"
local QIBuffer = require "quickimpl.io.buffer"
local DeclarationFactory = require "quickimpl.treesitter.declaration.decl_factory"

local M = {}
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
  while node ~= nil and not (DeclarationFactory(node)) do
    node = node:parent()
  end
  return node
end

--------------------------------------------------------------------------------
--- Modules
--------------------------------------------------------------------------------

M.callback = function(params)
  local buffer = QIBuffer.new(0)
  -- local root = parser:parse()[1]:root()

  local group = vim.api.nvim_create_augroup('quickimpl', {})
  local ns = vim.api.nvim_create_namespace('quickimpl-ns')

  local cursor_node = get_cursor()
  local decl = DeclarationFactory(cursor_node)
  if not decl then return end

  ts_util.highlight_node(cursor_node, ns, decl:get_type())
  vim.print(decl:define())

  local id = vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    buffer = 0,
    callback = function()
      cursor_node = get_cursor()
      decl = DeclarationFactory(cursor_node)
      if not decl then return end
      ts_util.highlight_node(cursor_node, ns, decl:get_type())
    end,
  })

  vim.api.nvim_buf_set_keymap(0, "n", "<ESC>", "",{
    desc = "Cancel selection",
    callback = function()
      vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
      vim.api.nvim_del_autocmd(id)
      vim.api.nvim_buf_del_keymap(0, "n", "<ESC>")
    end
  })

  vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "",{
    desc = "Confirm declarable selection",
    callback = function()
      if cursor_node == nil then return end
      vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
      vim.api.nvim_del_autocmd(id)
      vim.api.nvim_buf_del_keymap(0, "n", "<CR>")
      vim.print(decl:define())
    end
  })
end

--------------------------------------------------------------------------------
return M
