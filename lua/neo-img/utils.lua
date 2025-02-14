local M = {}
local Image = require("neo-img.image")

function M.get_max_rows()
  return vim.o.lines - vim.o.cmdheight - 1
end

function M.get_dims(win)
  local config        = require('neo-img.config').get()
  local row, col      = unpack(vim.api.nvim_win_get_position(win))

  local max_rows      = M.get_max_rows()
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
  local new_offset   = {
    x = math.floor(config.offset.x * width_factor + 0.5),
    y = math.floor(config.offset.y * height_factor + 0.5)
  }

  local start_row    = row + new_offset.y
  local start_column = col + new_offset.x
  return new_size, start_row, start_column
end

function M.get_extension(filename)
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

local function get_oil_buf()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "oil" then
      return buf
    end
  end
  return nil
end

local function get_oil_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "oil" then
      return win
    end
  end
  return nil
end

function M.display_image(filepath, win)
  local config = require('neo-img.config').get()

  if config.bin_path == "" then
    vim.notify("ttyimg isn't installed, can't show img", vim.log.levels.ERROR)
    return
  end

  if vim.fn.filereadable(filepath) == 0 then
    vim.notify("File not found: " .. filepath, vim.log.levels.ERROR)
    return
  end

  local size, start_row, start_column = M.get_dims(win)
  local command = build_command(filepath, size)

  Image.Delete()
  Image.job = vim.fn.jobstart(command, {
    on_stdout = function(_, data)
      if data then
        local output = table.concat(data, "\n")
        vim.schedule(function()
          if Image.job then
            Image.job = nil
          end
          local oil_buf = get_oil_buf()
          Image.Create(win, start_row, start_column, output, { oil_buf }, filepath)
          Image.Prepare()
          Image.Draw()
        end)
      end
    end,
    stdout_buffered = true
  })
end

function M.get_oil_filepath()
  local oil = require("oil")
  local entry = oil.get_cursor_entry()
  local dir = oil.get_current_dir()

  if entry ~= nil then
    return dir .. entry.parsed_name
  end

  return ""
end

return M
