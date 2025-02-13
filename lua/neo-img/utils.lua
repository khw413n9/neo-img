local M = {}

local function clear_window_region()
  vim.api.nvim_command('mode')
end

local function get_max_rows()
  return vim.o.lines - vim.o.cmdheight - 1
end

local get_dims = function(win)
  local config        = require('neo-img.config').get()
  local row, col      = unpack(vim.api.nvim_win_get_position(win))

  local max_rows      = get_max_rows()
  local max_cols      = vim.o.columns
  local min_rows      = vim.api.nvim_win_get_height(win) -- Rows in the current window
  local min_cols      = vim.api.nvim_win_get_width(win)  -- Columns in the current window
  local width_factor  = min_cols / max_cols
  local height_factor = min_rows / max_rows
  if config.size_isnumber then
    if width_factor < height_factor then
      height_factor = width_factor
    elseif height_factor < width_factor then
      width_factor = height_factor
    end
  end

  local new_size     = {
    x = math.floor(config.size.x * width_factor),
    y = math.floor(config.size.y * height_factor)
  }
  local yoffset      = math.floor(config.offset.y * height_factor)
  yoffset            = yoffset > 3 and yoffset or 3
  local new_offset   = {
    x = math.floor(config.offset.x * width_factor),
    y = yoffset
  }

  local start_row    = row + new_offset.y
  local start_column = col + new_offset.x
  return new_size, start_row, start_column
end

local echoraw = function(str, start_row, start_column)
  local move_cursor = string.format("\27[%d;%dH", start_row, start_column)
  local full_str    = "\27[s" .. move_cursor .. str .. "\27[u"

  vim.fn.chansend(vim.v.stderr, full_str)
end

local get_extension = function(filename)
  return filename:match("^.+%.(.+)$")
end

local function build_command(filepath, size)
  local config = require('neo-img.config').get()
  local valid_configs = { iterm = true, kitty = true, sixel = true }
  if valid_configs[config.backend] then
    return { config.bin_path, "-m", config.resizeMode, "-w", size.x, "-h", size.y, '-f', 'sixel', "-p", config.backend,
      filepath }
  else
    return { config.bin_path, "-m", config.resizeMode, "-w", size.x, "-h", size.y, '-f', 'sixel', filepath }
  end
end

local display_image = function(filepath, win)
  local config = require('neo-img.config').get()
  if config.bin_path == "" then
    vim.notify("ttyimg isn't installed, can't show img")
    return
  end

  if vim.fn.filereadable(filepath) == 0 then
    vim.notify("File not found: " .. filepath, vim.log.levels.ERROR)
    return
  end

  local size, start_row, start_column = get_dims(win)

  -- new buffer so gibbrish won't show and remove the echo
  vim.api.nvim_win_call(win, function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_set_current_buf(buf)

    -- delete usless buf
    local prev_buf = vim.fn.bufnr('#')
    if prev_buf ~= -1 then
      vim.api.nvim_buf_delete(prev_buf, { force = true })
    end

    local augroup = vim.api.nvim_create_augroup("MyBufferGroup", { clear = true })
    vim.api.nvim_create_autocmd({ "WinScrolled", "BufHidden", "BufUnload" }, {
      buffer = buf,
      group = augroup,
      once = true,
      callback = function()
        clear_window_region()
      end,
    })
  end)

  local command = build_command(filepath, size)

  vim.fn.jobstart(command, {
    on_stdout = function(_, data)
      if data then
        local output = table.concat(data, "\n")
        vim.schedule(function()
          echoraw(output, start_row, start_column)
        end)
      end
    end,
    stdout_buffered = true
  })
end


function M.setup_autocommands()
  local config = require('neo-img.config').get()
  local group = vim.api.nvim_create_augroup('NeoImg', { clear = true })

  if config.auto_open then
    vim.api.nvim_create_autocmd({ "BufRead" }, {
      group = group,
      pattern = "*",
      callback = function()
        local filepath = vim.fn.expand('%:p')
        local ext = get_extension(filepath)

        if ext and config.supported_extensions[ext:lower()] then
          local win = vim.api.nvim_get_current_win()
          display_image(filepath, win)
        end
      end
    })

    -- adding oil.nvim preview support.
    -- maybe won't work if the user creates a new win manually, hence adding option to diable it
    if config.oil_preview then
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "oil://*",
        callback = function()
          local wins = vim.api.nvim_list_wins()
          local active_win = vim.api.nvim_get_current_win()

          if #wins > 1 then
            for _, win in ipairs(wins) do
              if win ~= active_win then
                local oil = require("oil")
                local entry = oil.get_cursor_entry()
                local dir = oil.get_current_dir()
                if entry ~= nil then
                  local filepath = dir .. entry.parsed_name
                  local ext = get_extension(filepath)

                  if ext and config.supported_extensions[ext:lower()] then
                    display_image(filepath, win)
                  end
                end
                break
              end
            end
          end
        end,
      })
    end
  end

  -- Add command to manually trigger image display
  vim.api.nvim_create_user_command('NeoImgShow', function()
    local filepath = vim.fn.expand('%:p')
    M.display_image(filepath)
  end, {})
end

return M
