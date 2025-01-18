local M = {}

function M.get_extension(filename)
  return filename:match("^.+%.(.+)$")
end

function M.display_image(filepath)
  -- Check if file exists
  if vim.fn.filereadable(filepath) == 0 then
    vim.notify("File not found: " .. filepath, vim.log.levels.ERROR)
    return
  end

  -- Run viu
  vim.fn.termopen('viu -n "' .. filepath .. '"')
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
