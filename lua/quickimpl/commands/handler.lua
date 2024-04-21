local generate = require('quickimpl.commands.generate')

vim.api.nvim_create_user_command(generate.name, generate.callback, generate.opts)
