if vim.g.loaded_generate ~= nil then
  return
end
vim.g.loaded_generate = true

local M = {}

require('quickimpl.commands')

--------------------------------------------------------------------------------
--- public Methods
--------------------------------------------------------------------------------
M.setup = require('quickimpl.config').setup

return M
