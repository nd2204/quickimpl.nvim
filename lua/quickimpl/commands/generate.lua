local api = vim.api
local ts = vim.treesitter
local ts_util = require "quickimpl.treesitter"
local fs_util = require "quickimpl.io.filesystem"
local HeaderBuffer = require "quickimpl.io.header_buffer"
local DeclarationFactory = require "quickimpl.treesitter.declaration.decl_factory"
local SourceView = require "quickimpl.io.source_view"

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

local get_cursor = function(b)
  local node = ts.get_node({bufnr = b})
  local decl = DeclarationFactory(node, b)
  while node and not decl do
    node = node:parent()
    if not node then break end
    decl = DeclarationFactory(node, b)
  end
  return decl and decl:get_node() or nil
end

--------------------------------------------------------------------------------
--- Modules
--------------------------------------------------------------------------------

M.callback = function(params)
  local buf = api.nvim_get_current_buf()
  local srcview = assert(SourceView.new(buf, 'cpp'))
  
  local cursor_node = get_cursor(buf)
  local decl = DeclarationFactory(cursor_node, buf)
  if not decl then return end
  ts_util.highlight_node(cursor_node, srcview.ns, decl:get_type())

  local group = vim.api.nvim_create_augroup('quickimpl', {})

  local id = vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    buffer = buf,
    callback = function()
      cursor_node = get_cursor(buf)
      decl = DeclarationFactory(cursor_node, buf)
      if not decl then return end
      ts_util.highlight_node(cursor_node, srcview.ns, decl:get_type())
    end,
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", "",{
    desc = "Cancel selection",
    callback = function()
      vim.api.nvim_buf_clear_namespace(buf, srcview.ns, 0, -1)
      vim.api.nvim_del_autocmd(id)
      vim.api.nvim_buf_del_keymap(buf, "n", "<ESC>")
      vim.api.nvim_buf_del_keymap(buf, "n", "<CR>")
    end
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "",{
    desc = "Confirm declarable selection",
    callback = function()
      if cursor_node == nil then return end
      srcview:append(decl)
      srcview:refresh()
    end
  })
end

--------------------------------------------------------------------------------
return M
