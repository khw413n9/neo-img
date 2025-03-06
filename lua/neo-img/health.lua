local M = {}
local main_config = require "neo-img.config"
local utils = require "neo-img.utils"

function M.check()
  local config = main_config.get()
  local version = config.ttyimg_version
  vim.health.start("ttyimg Health Check")

  -- Run ttyimg --validate
  local result = vim.fn.system({ config.bin_path, "--validate", version })
  local versioned = string.match(result, "version")
  local exit_code = vim.v.shell_error

  -- ttyimg install location
  local location_type = config.ttyimg == "global" and "global (installed from go)" or
      "local (precompiled from `:NeoImg Install`)"
  vim.health.ok("expecting ttyimg to be " .. location_type)
  vim.health.info("PATH: " .. config.bin_path)

  -- ttyimg installation and version check
  if exit_code == 0 then
    vim.health.ok("ttyimg is installed and working correctly")
    vim.health.info("Validation output:\n" .. result)
    local backend_enf = config.backend == "auto" and "None" or config.backend
    vim.health.ok("backend enforcment: " .. backend_enf)
    vim.health.ok("fallback: " .. "sixel")
  else
    local install_message =
        "- Please call `:NeoImg Install`\n- or install it via `go install github.com/Skardyy/ttyimg@v" .. version .. "`"
    if versioned then
      vim.health.info("Validation output:\n" .. result)
      vim.health.error(
        "ttyimg version is invalid\n" .. install_message)
    else
      vim.health.error("ttyimg is outdated.\n" .. install_message)
    end
  end

  -- os and arch check
  local os, arch = utils.get_os_arch()
  if os == nil then
    vim.health.warn("OS: not supported on `:NeoImg Install`, please install from go")
  else
    vim.health.ok("OS (" .. os .. "): supported on both `go install` and `:NeoImg Install`")
  end

  if arch == nil then
    vim.health.warn("ARCH: not supported on `:NeoImg Install`, please install from go")
  else
    vim.health.ok("ARCH (" .. arch .. "): supported on both `go install` and `:NeoImg Install`")
  end

  -- screen size
  if config.window_size.spx.x == 1920 and config.window_size.spx.y == 1080 and os ~= "windows" then
    vim.health.warn("SPX: unless your terminal is 1920x1080, its likely failed to query the size")
  else
    if os == "windows" then
      vim.health.ok("SPX: " .. "will be queried from win api")
    else
      vim.health.ok("SPX: " .. vim.inspect(config.window_size.spx))
    end
  end
  vim.health.ok("SC: " .. vim.inspect(config.window_size.sc))
end

return M
