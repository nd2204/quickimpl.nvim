local M = {}

require('quickimpl.commands')

--------------------------------------------------------------------------------
--- public Methods
--------------------------------------------------------------------------------
M.setup = require('quickimpl.config').setup

local lazy_ok, lazy = pcall(require, "lazy.core.loader")

vim.api.nvim_create_user_command("QIReload", function()
  package.loaded.quickimpl = nil
  require("quickimpl")
  if lazy_ok then
    vim.print("RELOADING quickimpl")
    lazy.reload("quickimpl.nvim")
    vim.print("RELOADED quickimpl.nvim")
  else
    vim.print("RELOADING quickimpl")
    for name, _ in pairs(package.loaded) do
      if vim.startswith(name, 'quickimpl') then
        package.loaded[name] = nil
      end
    end
    vim.print("RELOADED quickimpl.nvim")
  end
end, {})

return M
