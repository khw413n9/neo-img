local M = {}
local utils = require("neo-img.utils")
local Image = require("neo-img.image")

local function setup_main(config)
  vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
    pattern = "*",
    callback = function(ev)
      Image.StopJob()
      vim.defer_fn(function()
        local filepath = vim.api.nvim_buf_get_name(ev.buf)
        if filepath == "" then
          filepath = utils.get_oil_filepath()
        end
        local ext = utils.get_extension(filepath)

        if ext and config.supported_extensions[ext:lower()] then
          local win = vim.fn.bufwinid(ev.buf)
          utils.display_image(filepath, win)
        end
      end, 10)
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
