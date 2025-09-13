--- TTY writing helper (wraps Neovim channels)
--- @class NeoImg.Tty
local M = {}

--- sends GP escape characters to the terminal
--- @param data string the escape characters to draw
--- Write raw escape sequence data to stderr channel (commonly recognized by terminals)
function M.write(data)
  vim.fn.chansend(vim.v.stderr, data)
end

return M
