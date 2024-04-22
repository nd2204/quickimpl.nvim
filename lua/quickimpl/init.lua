local M = {}

require('quickimpl.commands')

--------------------------------------------------------------------------------
--- public Methods
--------------------------------------------------------------------------------
M.setup = require('quickimpl.config').setup

vim.api.nvim_create_user_command("QIReload", function()
  package.loaded.quickimpl = nil
  vim.print("RELOADING quickimpl")
  require("quickimpl")
  if package.loaded.quickimpl then
    vim.print("RELOADED quickimpl")
  else
    vim.print("Unable to reload quickimpl")
  end
end, {})

return M
