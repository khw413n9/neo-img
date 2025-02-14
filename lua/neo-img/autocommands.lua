local M = {}
local utils = require("neo-img.utils")

local function setup_main(config)
  vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
    pattern = "*",
    callback = function(ev)
      local filepath = vim.api.nvim_buf_get_name(ev.buf)
      local ext = utils.get_extension(filepath)

      if ext and config.supported_extensions[ext:lower()] then
        local win = vim.fn.bufwinid(ev.buf)
        utils.display_image(filepath, win)
      end
    end
  })
end

local function setup_api()
end

function M:setup()
  local config = require("neo-img.config").get()
  if config.auto_open then
    setup_main(config)
  end
  setup_api()
end

return M
