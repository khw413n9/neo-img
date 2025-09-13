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
  -- width/height は cells (%サイズを cells 換算せずそのまま渡すのは暫定)
  -- WezTerm の `--width` `--height` はセル単位指定。ここでは % 指定を無視し "auto" に任せる簡易版。
  local cmd = { 'wezterm', 'imgcat', filepath }
  return cmd, 'imgcat'
end

return M
