local M = {}

--- Highlight node using Visual hlgroup
M.highlight_node = function(node, ns)
  local lnum, col, end_lnum, end_col = node:range()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(0, ns, lnum, col, {
    end_row = end_lnum,
    end_col = math.max(0, end_col),
    hl_group = 'Visual',
  })
end

return M
