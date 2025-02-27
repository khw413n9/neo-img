local M = {}

--- @class NeoImg.Config
--- @field supported_extensions table<string, boolean> Supported file extensions
--- @field size string Size of the image in percent (e.g., "80%")
--- @field center boolean Whether to center the image in the window
--- @field auto_open boolean Auto-open images on buffer load
--- @field oil_preview boolean Enable oil.nvim preview for images
--- @field backend "auto"|"kitty"|"iterm"|"sixel" Backend for rendering
--- @field resizeMode "Fit"|"Stretch"|"Crop" Resize mode for images
--- @field offset string Offset for positioning (e.g., "0x3")
--- @field bin_path? string Path to the ttyimg binary (populated at runtime)
--- @field os? string the OS of the machine (populated at runtime)
--- @field window_size? {spx: NeoImg.Size, sc: NeoImg.Size} window size fallbacks in px and cells (populated at runtime)

--- Default configuration
---@type NeoImg.Config
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
  size = "80%",  -- size of the image in percent
  center = true, -- rather or not to center the image in the window
  ----- Important ones -----

  ----- Less Important -----
  auto_open = true,   -- Automatically open images when buffer is loaded
  oil_preview = true, -- changes oil preview of images too
  backend = "auto",   -- auto / kitty / iterm / sixel
  resizeMode = "Fit", -- Fit / Strech / Crop
  offset = "2x3",     -- that exmp is 2 cells offset x and 3 y.
  ----- Less Important -----
}

local config = M.defaults

--- Get the directory where ttyimg is installed
---@return string bin_dir Path to the ttyimg binary directory
function M.get_bin_dir()
  local bin_name = "ttyimg"
  local config_dir = debug.getinfo(1).source:sub(2)
  local _, end_idx = config_dir:find("neo%-img")
  return config_dir:sub(1, end_idx) .. "/" .. bin_name
end

--- Get the path to the ttyimg binary
---@return string bin_path The resolved binary path or an empty string if not found
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

--- Set the bin_path in config
function M.set_bin_path()
  config.bin_path = M.get_bin_path()
end

--- Setup function to initialize the configuration
---@param opts? NeoImg.Config Custom user options
function M.setup(opts)
  config.bin_path = M.get_bin_path()
  config = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

--- Get the current configuration
---@return NeoImg.Config config The current configuration table
function M.get()
  return config
end

return M
