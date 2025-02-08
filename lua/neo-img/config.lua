local M = {}

M.defaults = {
  supported_extensions = {
    ['png'] = true,
    ['jpg'] = true,
    ['jpeg'] = true,
    ['gif'] = true,
    ['webp'] = true
  },
  auto_open = true,   -- Automatically open images when buffer is loaded
  oil_preview = true, -- changes oil preview of images too
  backend = "auto",   -- auto detect: kitty / iterm / sixel
  size = {            --scales the width, will maintain aspect ratio
    oil = 400,
    main = 800
  },
  offset = { -- only x offset
    oil = 5,
    main = 10
  }
}

local config = M.defaults

function M.setup(opts)
  config = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

function M.get()
  return config
end

return M
