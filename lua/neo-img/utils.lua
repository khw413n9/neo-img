local M = {}
local Image = require("neo-img.image")
local main_config = require("neo-img.config")

function M.get_max_rows()
  return vim.o.lines - vim.o.cmdheight - 1
end

local function get_scale_factor(value)
  local numberString = value:gsub("%%", "")
  local number = tonumber(numberString)
  if number < 1 then
    return number
  else
    return tonumber(numberString) / 100
  end
end

function M.get_dims(win)
  local config       = main_config.get()
  local row, col     = unpack(vim.api.nvim_win_get_position(win))

  local min_rows     = vim.api.nvim_win_get_height(win) -- Rows in the current window
  local min_cols     = vim.api.nvim_win_get_width(win)  -- Columns in the current window
  local scale_factor = get_scale_factor(config.size)

  local new_size     = {
    x = math.floor(min_cols * scale_factor + 0.5),
    y = math.floor(min_rows * scale_factor + 0.5)
  }

  local offsetx, offsety
  if not config.center then
    local tx, ty = config.offset:match("^(%d+)x(%d+)$")
    offsetx, offsety = tonumber(tx), tonumber(ty)
  end
  local new_offset   = {
    x = config.center and math.floor((min_cols - new_size.x) / 2 + 0.5) or offsetx,
    y = config.center and math.floor((min_rows - new_size.y) / 2 + 0.5) or offsety
  }

  new_size.x         = new_size.x .. "c"
  new_size.y         = new_size.y .. "c"

  local start_row    = row + new_offset.y
  local start_column = col + new_offset.x
  return new_size, start_row, start_column
end

function M.get_extension(filename)
  return filename:match("^.+%.(.+)$")
end

local function build_command(filepath, size)
  local rows = vim.o.lines - vim.o.cmdheight - 1
  local cols = vim.o.columns
  local sizeCells = cols .. "x" .. rows .. "xforce"

  local config = main_config.get()
  local valid_configs = { iterm = true, kitty = true, sixel = true }
  if valid_configs[config.backend] then
    return { config.bin_path, "-m", config.resizeMode, "-sc", sizeCells, "-spx", config.window_size, "-center=false",
      "-w", size.x, "-h", size.y,
      '-f', 'sixel',
      "-p", config.backend,
      filepath }
  else
    return { config.bin_path, "-m", config.resizeMode, "-sc", sizeCells, "-spx", config.window_size, "-center=false",
      "-w", size.x, "-h", size.y,
      '-f', 'sixel',
      filepath }
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

function M.is_window_large_enough(win)
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines

  local win_width = vim.api.nvim_win_get_width(win)
  local win_height = vim.api.nvim_win_get_height(win)

  local min_width = screen_width * 0.3
  local min_height = screen_height * 0.3

  return win_width >= min_width and win_height >= min_height
end

local function draw_image(config, win, row, col, output, filepath)
  local watch = config.oil_preview and { get_oil_buf() } or {}
  Image.Create(win, row, col, output, watch, filepath)
  Image.Prepare()
  Image.Draw()
end

function M.display_image(filepath, win)
  local config = main_config.get()

  if config.bin_path == "" then
    vim.notify("ttyimg isn't installed, call :NeoImg Install", vim.log.levels.ERROR)
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
        -- error
        if string.len(vim.inspect(data)) < 100 then
          -- if empty probbs just stopjob
          if output == "" then return end
          vim.notify("error: " .. output)
          return
        end
        vim.schedule(function()
          if Image.job ~= nil then
            Image.job = nil
          end
          draw_image(config, win, start_row, start_column, output, filepath)
        end)
      end
    end,
    stdout_buffered = true
  })
end

function M.setup_oil()
  local status_ok, oil = pcall(require, "oil.config")
  if not status_ok then return end

  if oil.preview_win ~= nil then
    oil.preview_win.disable_preview = function(filepath)
      local ext = M.get_extension(filepath)
      if main_config.get().supported_extensions[ext] then
        return true
      end
    end
  end
  return false
end

function M.lock_buf(buf)
  -- make it empty and not saveable, dk if all things are needed
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "readonly", true)
end

function M.get_oil_filepath()
  if main_config.get().oil_preview then
    local status_ok, oil = pcall(require, "oil")
    if not status_ok then return "" end

    local entry = oil.get_cursor_entry()
    local dir = oil.get_current_dir()

    if entry ~= nil then
      return dir .. entry.parsed_name
    end
  end

  return ""
end

return M
