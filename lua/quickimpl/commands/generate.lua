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
  local decl = DeclarationFactory(node) 
  while node and not decl do
    node = node:parent()
    if not node then break end
    decl = DeclarationFactory(node)
  end
  return decl and decl:get_node() or nil
end

---@param w integer
---@return boolean closed Whether the window was closed.
local function close_win(w)
  if api.nvim_win_is_valid(w) then
    api.nvim_win_close(w, true)
    return true
  end
  return false
end


--------------------------------------------------------------------------------
--- Modules
--------------------------------------------------------------------------------

M.callback = function(params)
  local buf = api.nvim_get_current_buf()
  local win = api.nvim_get_current_win()
  local srcview = assert(SourceView:new(buf, 'cpp'))
  
  if vim.b[buf].dev_impl then
    close_win(vim.b[buf].dev_impl)
  end

  local path = fs_util.get_sourcefile_equivalence(srcview.path, srcview.lang)
  if vim.fn.filereadable(path) then
  end
  vim.cmd('vsplit '.. path)
  local w = api.nvim_get_current_win()
  local b = api.nvim_get_current_buf()
  
  vim.b[buf].dev_impl = w
  vim.b[b].dev_base = win -- base window handle

  api.nvim_set_current_win(win)
  api.nvim_set_current_buf(buf)

  local cursor_node = get_cursor(buf)
  local decl = DeclarationFactory(cursor_node)
  if not decl then return end

  ts_util.highlight_node(cursor_node, srcview.ns, decl:get_type())
  for _, def in pairs(decl:define()) do
    vim.print(def)
  end

  local group = vim.api.nvim_create_augroup('quickimpl', {})

  local id = vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    buffer = 0,
    callback = function()
      cursor_node = get_cursor()
      decl = DeclarationFactory(cursor_node)
      if not decl then return end
      ts_util.highlight_node(cursor_node, srcview.ns, decl:get_type())
    end,
  })

  vim.api.nvim_buf_set_keymap(0, "n", "<ESC>", "",{
    desc = "Cancel selection",
    callback = function()
      vim.api.nvim_buf_clear_namespace(0, srcview.ns, 0, -1)
      vim.api.nvim_del_autocmd(id)
      vim.api.nvim_buf_del_keymap(0, "n", "<ESC>")
      vim.api.nvim_buf_del_keymap(0, "n", "<CR>")
    end
  })

  vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "",{
    desc = "Confirm declarable selection",
    callback = function()
      if cursor_node == nil then return end
      for _, def in pairs(decl:define()) do
        fs_util.file_append_content(path, def)
      end
      api.nvim_set_current_win(w)
      vim.cmd("edit")
      api.nvim_set_current_win(win)
    end
  })
end

--------------------------------------------------------------------------------
return M
