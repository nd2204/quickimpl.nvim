local ts = vim.treesitter
local api = vim.api
local fs_util = require "quickimpl.io.filesystem"
local DeclFactory = require "quickimpl.treesitter.declaration.decl_factory"

-------------------------------------------------------------------------------

local function traverse(node, tree)
  for child in node:iter_children() do
    local decl = DeclFactory(child)
    if decl then
      table.insert(tree, decl:get_declaration())
    else
      traverse(child ,tree)
    end
  end
  return tree
end
 
-------------------------------------------------------------------------------

---@class SourceBuffer
---@field bufnr integer buffer handle
---@field parser LanguageTree
---@field path string
---@field root TSNode
---@field lang string
local SourceView = {}

-------------------------------------------------------------------------------

function SourceView:new(bufnr, lang)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr or 0, lang)
  if not ok then
    local err = parser
    return nil, 'No parser available for the given buffer:\n' .. err
  end


  local t = {
    ns = api.nvim_create_namespace("quickimpl/dev-impl"),
    bufnr = bufnr or vim.api.nvim_get_current_buf(),
    path = api.nvim_buf_get_name(bufnr),
    parser = parser,
    lang = lang,
    decl = traverse(parser:parse()[1]:root(), {}),
  }

  vim.print(t.decl)

  setmetatable(t, self)
  self.__index = self
 return t
end

function SourceView:append(bufnr, content)
  local path = api.nvim_buf_get_name(bufnr)
  fs_util.file_append_content(path, content)
end

-------------------------------------------------------------------------------

return SourceView
