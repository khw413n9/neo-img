local M = {}

M.defaults = {
  supported_extensions = {
    ['png'] = true,
    ['jpg'] = true,
    ['jpeg'] = true,
    ['webp'] = true,
    ['svg'] = true,
    ['tiff'] = true,
  },
  auto_open = true,   -- Automatically open images when buffer is loaded
  oil_preview = true, -- changes oil preview of images too
  backend = "auto",   -- auto / kitty / iterm / sixel
  size = {            -- going to scale down based on the window to the entire screen, you can also pass size as a numebr and its going to set both that number (will scale them down together as well)
    x = 800,
    y = 800
  },
  offset = { -- going to scale down based on the window to the entire screen, setting a number will default y to 3 and x to the number
    x = 10,
    y = 3
  },
  resizeMode = "Fit" -- Fit / Strech / Crop
}

local config = M.defaults

local function get_bin_path()
  local plugin_name = "neo-img"
  local bin_src = "/ttyimg"
  local bin_name = "ttyimg"

  local function check_bin(dir, base_name)
    local scandir = vim.loop.fs_scandir(dir)
    while true do
      local entry = vim.loop.fs_scandir_next(scandir)
      if not entry then
        break
      end

      if entry:sub(1, #base_name) == base_name then
        return entry
      end
    end

    return nil
  end

  local data_dir = vim.fn.stdpath("data")
  if pcall(require, "lazy") then
    local bin_dir = data_dir .. "/lazy/" .. plugin_name .. bin_src
    local bin_path = check_bin(bin_dir, bin_name)
    if bin_path then
      return bin_path
    end
  end
  if pcall(require, "packer") then
    local bin_dir = data_dir .. "/site/pack/packer/start/" .. plugin_name .. bin_src
    local bin_path = check_bin(bin_dir, bin_name)
    if bin_path then
      return bin_path
    end
  end
  local global_binary = vim.fn.exepath("ttyimg")
  if global_binary ~= "" then
    return global_binary
  else
    print("No plugin manager detected and ttyimg is not installed globally. Please install ttyimg manually.")
    return ""
  end
end

function M.setup(opts)
  config.bin_path = get_bin_path()
  -- Normalize size options before merging
  config.size_isnumber = true
  config.offset_isnumber = true
  if opts and opts.size then
    if type(opts.size) == 'number' then
      opts.size = { x = opts.size, y = opts.size }
      config.size_isnumber = true
    end
  end
  -- Normalize offset options
  if opts and opts.offset then
    if type(opts.offset) == 'number' then
      opts.offset = { x = opts.offset, y = M.defaults.offset.y }
      config.offset_isnumber = true
    end
  end
  config = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

function M.get()
  return config
end

return M
