--- ttyimg backend descriptor (default external engine)
-- engine vs backend fields:
--  * config.engine selects implementation module (ttyimg external job vs dummy inline etc.)
--  * config.backend selects protocol flavor for ttyimg (-p value: auto/kitty/iterm/sixel)
-- For now only ttyimg supports multiple protocols; dummy ignores protocol.
local M = {}

-- backend descriptor for ttyimg
M.name = 'ttyimg'
M.persistent = false
M.protocols = { auto = true, kitty = true, iterm = true, sixel = true }

--- Build the command line for ttyimg
--- @param filepath string absolute path of image file
--- @param opts {spx:string, sc:string, scale:string, width:string, height:string}
--- @param config NeoImg.Config
--- @return table cmd array suitable for jobstart
--- @return string protocol resolved protocol name
--- Build ttyimg command arguments & chosen protocol
function M.build(filepath, opts, config)
  local protocol = 'auto'
  if M.protocols[config.backend] and config.backend ~= 'auto' then
    protocol = config.backend
  end
  local command = {
    config.bin_path, '-m', config.resizeMode, '-spx', opts.spx, '-sc', opts.sc,
    '-center=' .. tostring(config.center), '-scale', opts.scale,
    '-p', protocol, '-w', opts.width, '-h', opts.height, '-f', 'sixel', filepath
  }
  return command, protocol
end

return M
