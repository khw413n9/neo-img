local M = {}

-- Function to check if viu is installed
function M.check_viu_installation()
  local handle = io.popen('which viu')
  local result = handle:read('*a')
  handle:close()
  return result ~= ''
end

-- Function to install viu using cargo
function M.install_viu()
  vim.fn.system('cargo install viu')
end

-- Function to get file extension
function M.get_extension(filename)
  return filename:match("^.+%.(.+)$")
end

-- Function to create floating window
function M.create_float_window()
  local config = require('neo-img.config').get()
  local width = math.floor(vim.o.columns * config.window.width)
  local height = math.floor(vim.o.lines * config.window.height)
  local buf = vim.api.nvim_create_buf(false, true)

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = config.window.border
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  return buf, win
end

-- Function to display image
function M.display_image(filepath)
  if not M.check_viu_installation() then
    vim.notify("viu is not installed. Installing now...", vim.log.levels.INFO)
    M.install_viu()
  end

  local buf, win = M.create_float_window()

  -- Run viu with the -n flag to disable ANSI colors
  local command = string.format('viu -n "%s"', filepath)
  local handle = io.popen(command)
  local result = handle:read('*a')
  handle:close()

  -- Function to strip ANSI escape sequences if any remain
  local function strip_ansi(str)
    return str:gsub('\27%[[0-9;]*m', '')
  end

  -- Split the output into lines and strip ANSI codes
  local lines = {}
  for line in result:gmatch("[^\r\n]+") do
    table.insert(lines, strip_ansi(line))
  end

  -- Set the lines in the buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Make the buffer read-only
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Close window with q
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
end

-- Function to setup autocommands
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
