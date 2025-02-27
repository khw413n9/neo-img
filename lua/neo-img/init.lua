local M = {}
local config = require('neo-img.config')
local autocmds = require("neo-img.autocommands")
local utils = require("neo-img.utils")

function M.setup(opts)
  opts = opts or {}
  config.setup(opts)
  config.get().window_size = utils.get_window_size_fallback()
  autocmds.setup()
end

function M.install()
  local target_dir = config.get_bin_dir()

  local os, arch, osOk, archOk = require("neo-img.utils").get_os_arch()
  if not osOk then
    print("Unsupported OS: " .. os)
    return
  end
  if not archOk then
    print("Unsupported architecture: " .. arch)
    return
  end

  -- Build file name
  local filename = "ttyimg-" .. os .. "-" .. arch
  if os == "windows" then
    filename = filename .. ".exe"
  end

  -- Download URL
  local url = "https://github.com/Skardyy/ttyimg/releases/latest/download/" .. filename
  local output_path = target_dir .. "/ttyimg" .. (os == "windows" and ".exe" or "")

  -- Check if curl or wget is available
  local function is_command_available(cmd)
    return vim.fn.executable(cmd) == 1
  end

  local downloader
  if is_command_available("curl") then
    downloader = { "curl", "-L", "-o", output_path, url }
  elseif is_command_available("wget") then
    downloader = { "wget", "-O", output_path, url }
  else
    print("Neither curl nor wget found. Please install one.")
    return
  end

  -- Run the download command
  local handle = vim.loop.spawn(downloader[1], { args = { unpack(downloader, 2) } }, function(code, signal)
    if code == 0 then
      print("Downloaded ttyimg successfully to " .. output_path)

      -- Perform chmod to make the binary executable (only for non-Windows systems)
      if os ~= "windows" then
        local chmod_handle = vim.loop.spawn("chmod", { args = { "+x", output_path } }, function(chmod_code)
          if chmod_code == 0 then
            print("done installing ttyimg!")
            vim.schedule(function()
              config.set_bin_path()
            end)
          else
            print("Failed to set executable permissions for " .. output_path)
          end
        end)

        if not chmod_handle then
          print("Failed to start chmod process.")
        end
      else
        print("done installing ttyimg!")
        vim.schedule(function()
          config.set_bin_path()
        end)
      end
    else
      print("Failed to download ttyimg. Exit code: " .. code .. ", Signal: " .. signal)
    end
  end)

  if not handle then
    print("Failed to start download process.")
  end
end

return M
