--- @class NeoImg.Tty
local M = {}

--- sends GP escape characters to the terminal
--- @param data string the escape characters to draw
function M.write(data)
  vim.fn.chansend(vim.v.stderr, data)
end

return M
