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


local function build_ttyimg()
  local go_dir = vim.fn.stdpath("config") .. "/ttyimg" -- Path to the submodule
  config.binary_path = go_dir .. "/ttyimg"             -- Path to the binary

  -- Run `go build` to compile the binary
  local result = vim.system({
    "go", "build", "-o", config.binary_path
  }, { cwd = go_dir }):wait()

  if result.code ~= 0 then
    error("Failed to build ttyimg: " .. result.stderr)
  end

  print("Successfully built ttyimg!")
end

local function setup_plugin()
  if pcall(require, "packer") then
    -- Configure for packer.nvim
    require("packer").startup(function(use)
      use({
        "skardyy/neo-img",
        run = function()
          build_ttyimg()
        end,
      })
    end)
  elseif pcall(require, "lazy") then
    -- Configure for lazy.nvim
    require("lazy").setup({
      {
        "skardyy/neo-img",
        build = function()
          build_ttyimg()
        end,
      },
    })
  else
    -- No plugin manager detected
    vim.notify(
      "No plugin manager detected! Please run `go install github.com/Skardyy/ttyimg@latest`.",
      vim.log.levels.WARN
    )
  end
end

function M.setup(opts)
  setup_plugin()
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
