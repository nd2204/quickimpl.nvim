local M = {}

---@return (any) default if nil
---@return (any) result if not nil
function M.default_if_nil(default_val, val)
  return nil == val and default_val or val
end

return M
