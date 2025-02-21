local M = {}

M.defaults = {
  supported_extensions = {
    ['png'] = true,
    ['jpg'] = true,
    ['jpeg'] = true,
    ['webp'] = true,
    ['svg'] = true,
    ['tiff'] = true,
    ['tif'] = true,
    ['docx'] = true,
    ['xlsx'] = true,
    ['pdf'] = true,
    ['pptx'] = true,
  },
  ----- Important ones -----
  window_size = "1920x1080", -- size of the window. in windows auto queries using windows api, linux in the TODO. see below how to get the size of window in linux
  size = "80%",              -- size of the image in percent
  center = true,             -- rather or not to center the image in the window
  ----- Important ones -----

  ----- Less Important -----
  auto_open = true,   -- Automatically open images when buffer is loaded
  oil_preview = true, -- changes oil preview of images too
  backend = "auto",   -- auto / kitty / iterm / sixel
  resizeMode = "Fit", -- Fit / Strech / Crop
  offset = "0x3"      -- that exmp is 0 cells offset x and 3 y. options i irrelevant when centered
  ----- Less Important -----
}

local config = M.defaults

function M.get_bin_dir()
  local bin_name = "ttyimg"
  local config_dir = debug.getinfo(1).source:sub(2)
  local _, end_idx = config_dir:find("neo%-img")
  return config_dir:sub(1, end_idx) .. "/" .. bin_name
end

function M.get_bin_path()
  local bin_dir = M.get_bin_dir()
  local bin_path = bin_dir .. "/ttyimg"

  local local_bin = vim.fn.exepath(bin_path)
  if local_bin ~= "" then
    return local_bin
  end

  local global_binary = vim.fn.exepath("ttyimg")
  if global_binary ~= "" then
    return global_binary
  else
    print("couldn't find ttyimg, please call :NeoImg Install")
    return ""
  end
end

function M.set_bin_path()
  config.bin_path = M.get_bin_path()
end

function M.setup(opts)
  config.bin_path = M.get_bin_path()
  config = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

function M.get()
  return config
end

return M
