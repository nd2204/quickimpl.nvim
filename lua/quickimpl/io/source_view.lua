local ts = vim.treesitter
local api = vim.api
local config = require "quickimpl.config"
local fs_util = require "quickimpl.io.filesystem"
local DeclFactory = require "quickimpl.treesitter.declaration.decl_factory"

-------------------------------------------------------------------------------

local function traverse_decl(node, tree, buf)
  tree = tree or {}
  for child in node:iter_children() do
    local decl = DeclFactory(child, buf)
    if decl then
      tree[child] = decl
    else
      traverse_decl(child ,tree)
    end
  end
  return tree
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
 
-------------------------------------------------------------------------------

---@class SourceBuffer
---@field bufnr integer buffer handle
---@field ns integer namespace
---@field win integer window handle
---@field parser table<LanguageTree>
---@field path string
---@field root TSNode
---@field lang string
local SourceView = {}
SourceView.__index = SourceView

-------------------------------------------------------------------------------

function SourceView.new(bufnr, lang)
  local self = setmetatable({}, SourceView)
  local ok
  self.parser = {}
  ok, self.parser['dev_base'] = pcall(vim.treesitter.get_parser, bufnr or 0, lang)
  if not ok then
    local err = self.parser['dev_base']
    return nil, 'No parser available for the given buffer:\n' .. err
  end

  local win = api.nvim_get_current_win()

  if vim.b[bufnr].dev_impl then
    close_win(vim.b[bufnr].dev_impl)
  end

  local path = fs_util.get_sourcefile_equivalence(api.nvim_buf_get_name(bufnr), lang)

  vim.cmd('vsplit '.. path)
  local w = api.nvim_get_current_win()
  local b = api.nvim_get_current_buf()
  
  vim.b[bufnr].dev_impl = w
  vim.b[b].dev_base = win -- base window handle
  vim.b[b].dev_base_buf = bufnr -- base window handle

  api.nvim_set_current_win(win)

  ok, self.parser['dev_impl'] = pcall(vim.treesitter.get_parser, b, lang)
  if not ok then
    local err = self.parser['dev_impl']
    return nil, 'No parser available for the given buffer:\n' .. err
  end

  self.ns = api.nvim_create_namespace("quickimpl/dev-impl")
  self.bufnr = b
  self.win = w
  self.path = api.nvim_buf_get_name(b)
  self.lang = lang

  self.defined = {}
  -- for _, v in pairs(defs) do
  --   vim.print(v:get_declaration())
  -- end
  return self
end

---@param decl ClassDeclaration|FunctionDeclaration
function SourceView:append(decl)
  local defs = traverse_decl(self.parser['dev_impl']:parse()[1]:root(), {}, self.bufnr)
  for _, v in pairs(defs) do
    for _, def in pairs(v:get_declaration()) do
      self.defined[def] = true
    end
  end
  for _, v in pairs(decl:get_declaration()) do
    if self.defined[v] then
      vim.notify(v.." Already Implemented")
    else
      fs_util.file_append_content(self.path, v..config.get_key_value('brace_pattern'))
      self.defined[v] = true
    end
  end
end

function SourceView:refresh()
  api.nvim_set_current_win(self.win)
  vim.cmd("edit")
  api.nvim_set_current_win(vim.b[self.bufnr].dev_base)
end

function SourceView:close()
  local base_win = vim.b[self.bufnr].dev_base
  local base_buf = vim.b[self.bufnr].dev_base_buf
  api.nvim_set_current_win(self.bufnr)
  vim.cmd("bd")
  api.nvim_set_current_win(base_win)
  vim.b[base_buf].dev_impl = nil
end

-------------------------------------------------------------------------------

return SourceView
