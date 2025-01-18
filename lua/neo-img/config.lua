local M = {}

M.defaults = {
  supported_extensions = {
    ['png'] = true,
    ['jpg'] = true,
    ['jpeg'] = true,
    ['gif'] = true,
    ['webp'] = true
  },
  window = {
    width = 0.8,      -- Percentage of screen width
    height = 0.8,     -- Percentage of screen height
    border = 'rounded'
  },
  auto_open = true   -- Automatically open images when buffer is loaded
}

local config = M.defaults

function M.setup(opts)
  config = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

function M.get()
  return config
end

return M
