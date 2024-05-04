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
    lazy.reload("quickimpl.nvim")
  else
    for name, _ in pairs(package.loaded) do
      if vim.startswith(name, 'quickimpl') then
        package.loaded[name] = nil
      end
    end
  end
end, {})

vim.keymap.set("n", "<leader>ir", "<CMD>QIReload<CR>", {desc = "Reload Quickimpl"})
vim.keymap.set("n", "<leader>ig", "<CMD>QIGenerate<CR>", {desc = "Generate implementation"})

return M
