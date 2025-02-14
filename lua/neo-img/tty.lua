local M = {}
local stdout = vim.loop.new_tty(1, false)

function M.write(data)
  stdout:write(data)
end

return M
