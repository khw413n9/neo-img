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
  auto_open = true,   -- Automatically open images when buffer is loaded
  oil_preview = true, -- changes oil preview of images too
  backend = "auto",   -- auto / kitty / iterm / sixel
  size = {
    x = 800,
    y = 800
  },
  offset = {
    x = 10,
    y = 3
  },
  resizeMode = "Fit" -- Fit / Strech / Crop
}

local config = M.defaults

local function get_bin_path()
  local bin_name = "ttyimg/ttyimg"
  local config_dir = debug.getinfo(1).source:sub(2)
  local _, end_idx = config_dir:find("neo%-img")
  local bin_path = config_dir:sub(1, end_idx) .. "/" .. bin_name

  local local_bin = vim.fn.exepath(bin_path)
  if local_bin ~= "" then
    return local_bin
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
  config = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

function M.get()
  return config
end

return M
