local M = {}
local utils = require("neo-img.utils")
local Image = require("neo-img.image")
local main_config = require("neo-img.config")

local function setup_main(config)
  -- lock bufs on read
  vim.api.nvim_create_autocmd({ "BufRead" }, {
    pattern = "*",
    callback = function(ev)
      local filepath = vim.api.nvim_buf_get_name(ev.buf)
      if filepath == "" then return end
      local ext = utils.get_extension(filepath)
      if ext and config.supported_extensions[ext:lower()] then
        utils.lock_buf(ev.buf)
      end
    end
  })

  -- preview image on buf win enter
  vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
    pattern = "*",
    callback = function(ev)
      Image.StopJob()
      vim.defer_fn(function()
        local filepath = vim.api.nvim_buf_get_name(ev.buf)
        -- oil doesn't name its buffers, im also disabling preview so..
        if filepath == "" then
          filepath = utils.get_oil_filepath()
        end
        local ext = utils.get_extension(filepath)

        if ext and config.supported_extensions[ext:lower()] then
          local win = vim.fn.bufwinid(ev.buf)
          -- show only on win that are at least 30% xy. stops random wins from getting images on them lol
          if utils.is_window_large_enough(win) then
            utils.display_image(filepath, win)
          end
        end
      end, 10)
    end
  })
end

local function setup_api()
  vim.api.nvim_create_user_command('NeoImg', function(opts)
    local command_name = opts.args
    if command_name == 'Install' then
      print("Installing Ttyimg...")
      require("neo-img").install()
    elseif command_name == 'DisplayImage' then
      local buf_name = vim.api.nvim_buf_get_name(0)
      local current_win = vim.api.nvim_get_current_win()
      if buf_name ~= "" then
        utils.display_image(buf_name, current_win)
      end
    end
  end, {
    nargs = 1,
    complete = function()
      return { 'Install', 'DisplayImage' }
    end
  })
end

function M:setup()
  local config = main_config.get()
  vim.g.zipPlugin_ext = "zip" -- showing image so no need for unzip
  if config.auto_open then
    setup_main(config)
  end
  if config.oil_preview then
    utils.setup_oil() -- disables preview for files that im already showing image preview
  end
  setup_api()
end

return M
