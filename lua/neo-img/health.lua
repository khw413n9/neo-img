local M = {}
local main_config = require "neo-img.config"

function M.check()
  local config = main_config.get()
  local version = "1.0.5"
  vim.health.start("ttyimg Health Check")

  -- Run ttyimg --validate
  local result = vim.fn.system({ config.bin_path, "--validate", version })
  local versioned = string.match(result, "version")
  local exit_code = vim.v.shell_error

  if exit_code == 0 then
    vim.health.ok("ttyimg is installed and working correctly")
    vim.health.info("Validation output:\n" .. result)
    local backend_enf = config.backend == "auto" and "None" or config.backend
    vim.health.ok("backend enforcment:\n" .. backend_enf)
    vim.health.ok("fallback:\n" .. "sixel")
  else
    local install_message =
    "- Please call `:NeoImg Install`\n- or install it via `go install github.com/Skardyy/ttyimg@v1.0.5`"
    if versioned then
      vim.health.info("Validation output:\n" .. result)
      vim.health.error(
        "ttyimg version is invalid\n")
      vim.health.warn("if the got is bigger then the expects:\n" .. install_message)
      vim.health.warn("if the got is smaller then the expects:\n- please update the plugin (may not be needed)")
    else
      vim.health.error("ttyimg validation failed.\neither version is outdated or ttyimg isn't installed\n" ..
        install_message)
    end
  end
end

return M
