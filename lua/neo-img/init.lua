local M = {}
local config = require('neo-img.config')
local autocmds = require("neo-img.autocommands")

function M.setup(opts)
  opts = opts or {}
  config.setup(opts)
  autocmds:setup()
end

function M.install()
  local uname = vim.loop.os_uname()
  local os, arch = uname.sysname:lower(), uname.machine

  -- Normalize OS name
  if os:find("linux") then
    os = "linux"
  elseif os:find("darwin") then
    os = "darwin"
  elseif os:find("windows") then
    os = "windows"
  else
    print("Unsupported OS: " .. os)
    return
  end

  -- Normalize Architecture
  if arch == "x86_64" then
    arch = "amd64"
  elseif arch == "aarch64" then
    arch = "arm64"
  elseif arch:find("arm") then
    arch = "arm"
  elseif arch:find("i386") or arch:find("i686") then
    arch = "386"
  else
    print("Unsupported architecture: " .. arch)
    return
  end

  -- Build file name
  local filename = "ttyimg-" .. os .. "-" .. arch
  if os == "windows" then filename = filename .. ".exe" end

  -- Download URL
  local url = "https://github.com/Skardyy/ttyimg/releases/latest/download/" .. filename
  local output_path = "ttyimg/ttyimg" .. (os == "windows" and ".exe" or "")

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
  local handle = vim.loop.spawn(downloader[1], { args = { unpack(downloader, 2) } }, function(code)
    if code == 0 then
      if os ~= "windows" then
        vim.loop.spawn("chmod", { args = { "+x", output_path } })
      end
      print("Downloaded ttyimg successfully!")
    else
      print("Failed to download ttyimg.")
    end
  end)

  if not handle then
    print("Failed to start download process.")
  end
end

return M
