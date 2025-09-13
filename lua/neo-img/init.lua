---
--- Neo-Img public entrypoint
--- Responsibilities:
---  * Merge user configuration with defaults
---  * Capture initial window size fallback (pixels + cells)
---  * Register autocommands and user commands
---  * Provide a helper to install/update the external `ttyimg` binary
---
local M = {}
local config = require('neo-img.config')
local autocmds = require("neo-img.autocommands")
local utils = require("neo-img.utils")

--- setups the plugin
--- Setup plugin (idempotent)
--- @param opts NeoImg.Config|nil
function M.setup(opts)
  opts = opts or {}
  config.setup(opts)
  config.get().window_size = utils.get_window_size_fallback()
  autocmds.setup()
end

--- installs ttyimg, which is a dependency for the plugin
--- Download & place prebuilt ttyimg into the plugin bin dir.
--- Falls back to user's globally installed ttyimg if preferred.
function M.install()
  local target_dir = config.get_bin_dir()

  local os, arch = require("neo-img.utils").get_os_arch()
  if os == nil then
    print("Unsupported OS")
    return
  end
  if arch == nil then
    print("Unsupported cpu architecture")
    return
  end

  -- Build file name
  local filename = "ttyimg-" .. os .. "-" .. arch
  if os == "windows" then
    filename = filename .. ".exe"
  end

  -- Download URL
  local version = "v" .. config.get().ttyimg_version
  local url = "https://github.com/Skardyy/ttyimg/releases/download/" .. version .. "/" .. filename
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
