local M = {}

function M.write(data)
  vim.fn.chansend(vim.v.stderr, data)
end

return M
