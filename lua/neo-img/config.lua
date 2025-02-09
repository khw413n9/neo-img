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

function M.setup(opts)
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
