local M = {}

function M.check_viu_installation()
  local handle = io.popen("viu --version 2>&1")
  local result = handle:read("*a")
  handle:close()

  -- Check if the output contains something meaningful (e.g., "viu" or version info)
  if result and result:match("viu") then
    return true
  else
    return false
  end
end

function M.install_viu()
  if vim.fn.executable('cargo') == 0 then
    vim.notify("cargo is not installed. Please install cargo first.", vim.log.levels.ERROR)
    return false
  end
  vim.notify("Installing viu...", vim.log.levels.INFO)
  local ret = vim.fn.system('cargo install viu')
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to install viu: " .. ret, vim.log.levels.ERROR)
    return false
  end
  return true
end

function M.get_extension(filename)
  return filename:match("^.+%.(.+)$")
end

function M.display_image(filepath)
  -- Check if file exists
  if vim.fn.filereadable(filepath) == 0 then
    vim.notify("File not found: " .. filepath, vim.log.levels.ERROR)
    return
  end

  -- Check for viu installation
  if not M.check_viu_installation() then
    if not M.install_viu() then
      return
    end
  end

  -- Run viu and capture its output
  local command = string.format('viu -n "%s"', filepath)
  local output = vim.fn.system(command)

  -- Check if viu succeeded
  if vim.v.shell_error ~= 0 then
    vim.notify("Error running viu: " .. output, vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  -- vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, '\n'))
  -- vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.fn.termopen('viu -n "' .. filepath .. '"')
  -- vim.cmd('startinsert')
end

function M.setup_autocommands()
  local config = require('neo-img.config').get()
  local group = vim.api.nvim_create_augroup('NeoImg', { clear = true })

  if config.auto_open then
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      group = group,
      pattern = "*",
      callback = function()
        local filepath = vim.fn.expand('%:p')
        local ext = M.get_extension(filepath)

        if ext and config.supported_extensions[ext:lower()] then
          M.display_image(filepath)
        end
      end
    })
  end

  -- Add command to manually trigger image display
  vim.api.nvim_create_user_command('NeoImgShow', function()
    local filepath = vim.fn.expand('%:p')
    M.display_image(filepath)
  end, {})
end

return M
