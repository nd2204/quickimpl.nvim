local ts = vim.treesitter
local api = vim.api

-------------------------------------------------------------------------------

---@class HeaderBuffer
---@field bufnr integer buffer handle
---@field parser LanguageTree
---@field path string
---@field root TSNode
local HeaderBuffer = {}
HeaderBuffer.__index = HeaderBuffer

-------------------------------------------------------------------------------

HeaderBuffer.new = function(bufnr)
  local self = setmetatable({}, HeaderBuffer)
  self.path = api.nvim_buf_get_name(bufnr)
  self.bufnr = bufnr or vim.api.nvim_get_current_buf()
  self.parser = ts.get_parser(bufnr)
  self.root = self.parser:parse()[1]:root()
  return self
end

--- Get buffer language
function HeaderBuffer:get_lang()
  return self.parser:lang()
end

--- Get full file path of a buffer
function HeaderBuffer:get_path()
  return self.path
end

function HeaderBuffer:get_parser()
  return self.parser
end

--- Get the root node of the parsed buffer
function HeaderBuffer:get_root()
  return self.parser:parse()[1]:root()
end

-------------------------------------------------------------------------------

return HeaderBuffer
