local M = {}
local config = require('neo-img.config')
local utils = require('neo-img.utils')

function M.setup(opts)
  opts = opts or {}
  config.setup(opts)
  require('neo-img.utils').setup_autocommands()
end

return M
