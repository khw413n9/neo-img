--- dummy backend descriptor (inline backend for experiments)
--- Produces a simple colored block / metadata text instead of real image.
local M = {}
M.name = 'dummy'
M.persistent = false
M.inline = true   -- signals utils.display_image to bypass jobstart

--- Build method kept for interface parity (ignored arguments)
function M.build(filepath, opts, config)
  -- simulate a small escape sequence representing an "image"
  local txt = string.format("Dummy Image\nfile: %s\nspx=%s sc=%s scale=%s size=%s\n",
    filepath, opts.spx or '?', opts.sc or '?', opts.scale or '?', opts.width or '?')
  -- simple cyan block using ANSI; real backends emit protocol escapes
  local esc = "\27[36m" .. txt .. "\27[0m"
  return esc, 'inline'
end

return M
