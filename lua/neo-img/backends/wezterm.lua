--- WezTerm imgcat backend
--- Uses: wezterm imgcat --width <cells> --height <cells> <file>
--- Notes:
---  * WezTerm の imgcat は kitty protocol 互換ではなく、独自 (OSC 1337 風) 形式
---  * 端末が WezTerm の場合のみ有効にする想定 (TERM_PROGRAM=WezTerm)
local M = {}
M.name = 'wezterm'
M.persistent = false
M.inline = false
M.protocols = { imgcat = true }

--- Build command for wezterm imgcat.
-- @param filepath string
-- @param opts table {spx, sc, scale, width, height}
-- @param config NeoImg.Config
-- @return table cmd, string protocol
function M.build(filepath, opts, config)
  -- opts.sc: "<cols>x<rows>xforce" 形式
  local cols = nil
  if opts and opts.sc then
    local c = opts.sc:match("^(%d+)x")
    cols = tonumber(c)
  end
  local pct = 80 --[[@as integer]]
  if config and type(config.size) == 'string' then
    local n = config.size:match("^(%d+)%%$")
    if n then
      local nn = tonumber(n)
      if nn then pct = math.floor(nn) end
    end
  end
  local width_cells = cols and math.max(1, math.floor(cols * (pct / 100))) or nil
  local cmd = { 'wezterm', 'imgcat' }
  if width_cells then
    table.insert(cmd, '--width')
    table.insert(cmd, tostring(width_cells))
  end
  table.insert(cmd, filepath)
  return cmd, 'imgcat'
end

return M
