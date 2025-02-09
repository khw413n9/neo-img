local M = {}

M.defaults = {
  supported_extensions = {
    ['png'] = true,
    ['jpg'] = true,
    ['jpeg'] = true,
    ['webp'] = true,
    ['svg'] = true,
    ['tiff'] = true
  },
  auto_open = true,             -- Automatically open images when buffer is loaded
  oil_preview = true,           -- changes oil preview of images too
  backend = "auto",             -- auto detect: kitty / iterm / sixel
  size = {                      --scales the width, will maintain aspect ratio
    oil = { x = 400, y = 400 }, -- a number (oil = 400) will set both at once
    main = { x = 800, y = 800 }
  },
  offset = {
    oil = { x = 5, y = 3 }, -- a number will only change the x
    main = { x = 10, y = 3 }
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
  if opts and opts.size then
    for k, v in pairs(opts.size) do
      if type(v) == 'number' then
        opts.size[k] = { x = v, y = v }
      end
    end
  end
  -- Normalize offset options
  if opts and opts.offset then
    for k, v in pairs(opts.offset) do
      if type(v) == 'number' then
        opts.offset[k] = { x = v, y = M.defaults.offset[k].y }
      end
    end
  end
  config = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

function M.get()
  return config
end

return M
