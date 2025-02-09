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

local function setup_plugin()
  local plugin_name = "neo-img"

  local plugin_dir
  local isPacker = pcall(require, "packer")
  local isLazy = pcall(require, "lazy")
  if isPacker then
    plugin_dir = vim.fn.stdpath("data") .. "/site/pack/packer/start/" .. plugin_name
  elseif isLazy then
    plugin_dir = vim.fn.stdpath("data") .. "/lazy/" .. plugin_name
  else
    vim.notify(
      "No plugin manager detected! Please build ttyimg manually",
      vim.log.levels.ERROR
    )
    return nil
  end

  local go_dir = plugin_dir .. "/ttyimg"
  local binary_path = go_dir .. "/ttyimg"

  local function build_ttyimg()
    local result = vim.system({
      "go", "build", "-o", binary_path
    }, { cwd = go_dir }):wait()

    if result.code ~= 0 then
      error("Failed to build ttyimg: " .. result.stderr)
    end

    print("Successfully built ttyimg!")
  end

  -- Setup for packer.nvim
  if isPacker then
    require("packer").startup(function(use)
      use({
        "Skardyy/" .. plugin_name,
        run = build_ttyimg,
      })
    end)
  end

  -- Setup for lazy.nvim
  if isLazy then
    require("lazy").setup({
      {
        "Skardyy/" .. plugin_name,
        build = build_ttyimg,
      },
    })
  end

  -- Return the binary path
  return binary_path
end

function M.setup(opts)
  config.bin_path = setup_plugin()
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
