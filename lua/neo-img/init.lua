local M = {}
local config = require('neo-img.config')
local autocmds = require("neo-img.autocommands")

function M.setup(opts)
  opts = opts or {}
  config.setup(opts)
  autocmds:setup()
end

return M
