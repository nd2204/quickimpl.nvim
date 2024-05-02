local ts = vim.treesitter
local api = vim.api

-------------------------------------------------------------------------------

---@class QIBuffer
---@field bufnr integer buffer handle
---@field parser LanguageTree
---@field path string
local QIBuffer = {}
QIBuffer.__index = QIBuffer

-------------------------------------------------------------------------------

QIBuffer.new = function(bufnr)
  local self = setmetatable({}, QIBuffer)
  self.path = api.nvim_buf_get_name(bufnr)
  self.bufnr = bufnr
  self.parser = ts.get_parser(bufnr)
  return self
end

--- Get buffer language
function QIBuffer:get_lang()
  return self.parser:lang()
end

--- Get full file path of a buffer
function QIBuffer:get_path()
  return self.path
end

function QIBuffer:get_parser()
  return self.parser
end

--- Get the root node of the parsed buffer
function QIBuffer:get_root()
  return self.parser:parse()[1]:root()
end

-------------------------------------------------------------------------------

return QIBuffer
