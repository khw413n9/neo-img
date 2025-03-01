--- @class NeoImg.Utils
local M = {}
local Image = require("neo-img.image")
local main_config = require("neo-img.config")

--- returns the os and arch
--- @return string os the OS of the machine
--- @return string arch the arch of the cpu
--- @return boolean osOk if the os is supported
--- @return boolean archOk if the arch is supported
function M.get_os_arch()
  local uname = vim.loop.os_uname()
  local os, arch = uname.sysname:lower(), uname.machine
  local osOk, archOk = true, true

  -- Normalize OS name
  if os:find("linux") then
    os = "linux"
  elseif os:find("darwin") then
    os = "darwin"
  elseif os:find("windows") then
    os = "windows"
  else
    osOk = false
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
    archOk = false
  end

  return os, arch, osOk, archOk
end

--- @class NeoImg.Size
--- @field x number
--- @field y number

--- returns a window size for fallback
--- @return {spx: NeoImg.Size, sc: NeoImg.Size}
function M.get_window_size_fallback()
  local config = main_config.get()
  local os = M.get_os_arch()
  config.os = os
  local spx = {
    x = 1920,
    y = 1080
  }
  local sc = {
    x = vim.o.columns,
    y = vim.o.lines
  }
  if config.os ~= "windows" then
    local ffi = require("ffi")
    ffi.cdef [[
    struct winsize {
        unsigned short ws_row;
        unsigned short ws_col;
        unsigned short ws_xpixel;
        unsigned short ws_ypixel;
    };

    int ioctl(int fd, unsigned long request, void *arg);
    ]]
    local TIOCGWINSZ = config.os == "linux" and 0x5413 or 0x40087468
    local winsize = ffi.new("struct winsize")
    local success = ffi.C.ioctl(0, TIOCGWINSZ, winsize)
    if success == 0 then
      spx.x = winsize.ws_xpixel
      spx.y = winsize.ws_ypixel
    end
  end
  return {
    spx = spx,
    sc = sc
  }
end

--- Normalizes the size of the img
--- @return string value
local function get_scale_factor(value)
  local numberString = value:gsub("%%", "")
  local number = tonumber(numberString)
  if number > 95 then
    return 95 .. "%"
  else
    return value
  end
end

--- Calculates dimensions for the image in the given win
--- @param win integer window id
--- @return {spx: string, sc: string, size: string, scale: string, offset: NeoImg.Size}
function M.get_dims(win)
  local config                   = main_config.get()

  local row, col                 = unpack(vim.api.nvim_win_get_position(win))
  local ovcol, ovrow             = vim.o.columns - col, vim.o.lines - row

  -- gettig factors
  local scale_factor             = get_scale_factor(config.size)
  local win_factor_x             = ovcol / vim.o.columns
  local win_factor_y             = ovrow / vim.o.lines

  -- getting the offset
  local offsetx, offsety         = 2, 3
  local tx, ty                   = config.offset:match("^(%d+)x(%d+)$")
  local offsetx_tmp, offsety_tmp = tonumber(tx), tonumber(ty)
  if offsetx_tmp then
    offsetx = offsetx_tmp
  end
  if offsety_tmp then
    offsety = offsety_tmp
  end

  -- getting size in px
  local spx = config.window_size.spx.x .. "x" .. config.window_size.spx.y
  if config.os ~= "windows" then
    spx = spx .. "xforce"
  end

  --getting size in cells
  local sc = config.window_size.sc.x .. "x" .. config.window_size.sc.y .. "xforce"

  --getting the scale
  local scale = win_factor_x .. "x" .. win_factor_y

  return {
    spx = spx,
    sc = sc,
    size = scale_factor,
    scale = scale,
    offset = {
      x = col + offsetx,
      y = row + offsety
    }
  }
end

--- @param filename string the filename to get the ext from
--- @return string the ext
function M.get_extension(filename)
  return filename:match("^.+%.(.+)$")
end

--- builds the command to run in order to get the img
--- @param filepath string the img to show
--- @param opts {spx: string, sc: string, scale: string, width: string, height: string}
--- @return table
local function build_command(filepath, opts)
  local config = main_config.get()

  local protocol = "auto"
  local valid_configs = { iterm = true, kitty = true, sixel = true }
  if valid_configs[config.backend] then
    protocol = config.backend
  end

  local command = {
    config.bin_path,
    "-m", config.resizeMode,
    "-spx", opts.spx,
    "-sc", opts.sc,
    "-center=" .. tostring(config.center),
    "-scale", opts.scale,
    "-p", protocol,
    "-w", opts.width, "-h", opts.height,
    "-f", "sixel",
    filepath
  }

  return command
end

--- @return integer? buf the main oil buf
local function get_oil_buf()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "oil" then
      return buf
    end
  end
  return nil
end

--- setup and draws the image
--- @param win integer the window id to listen on remove
--- @param row integer the starting row
--- @param col integer the starting col
--- @param output string the content of the image
--- @param filepath string the filepath to use as id
local function draw_image(win, row, col, output, filepath)
  local config = main_config.get()
  local watch = config.oil_preview and { get_oil_buf() } or {}
  Image.Create(win, row, col, output, watch, filepath)
  Image.Prepare()
  Image.Draw()
end

--- draws the image
--- @param filepath string the image to draw
--- @param win integer the window id to draw on
function M.display_image(filepath, win)
  local config = main_config.get()

  -- checks before draw
  if config.bin_path == "" then
    vim.notify("ttyimg isn't installed, call :NeoImg Install", vim.log.levels.ERROR)
    return
  end
  if vim.fn.filereadable(filepath) == 0 then
    vim.notify("File not found: " .. filepath, vim.log.levels.ERROR)
    return
  end

  local opts = M.get_dims(win)
  local command = build_command(filepath, {
    spx = opts.spx,
    sc = opts.sc,
    scale = opts.scale,
    width = opts.size,
    height = opts.size
  })

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
        draw_image(win, opts.offset.y, opts.offset.x, output, filepath)
      end
    end,
    stdout_buffered = true
  })
end

--- make a buf empty and unwritable
function M.lock_buf(buf)
  -- make it empty and not saveable, dk if all things are needed
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "readonly", true)
end

return M
