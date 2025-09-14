-- New comprehensive health integrating engine/cache/env checks
local M = {}
local config_mod = require('neo-img.config')
local utils = require('neo-img.utils')

local function start(title) vim.health.start(title) end
local function ok(msg) vim.health.ok(msg) end
local function warn(msg) vim.health.warn(msg) end
local function error_(msg) vim.health.error(msg) end
local function info(msg) vim.health.info(msg) end

local function check_engine(cfg)
  start('Engine')
  ok('engine=' .. tostring(cfg.engine))
  if cfg.engine == 'ttyimg' then
    if cfg.bin_path == '' then
      warn('ttyimg selected but bin_path empty (run :NeoImg Install)')
    else
      ok('ttyimg binary: ' .. cfg.bin_path)
      -- try lightweight validate. Accept both 'vX.Y.Z' and 'X.Y.Z'.
      local res = ''
      if vim.fn.filereadable(cfg.bin_path) == 1 then
        -- first attempt: without forced v prefix so we accept tool's native format
        res = vim.fn.system({ cfg.bin_path, '--validate', cfg.ttyimg_version })
        local exit = vim.v.shell_error
        if exit ~= 0 then
          -- fallback attempt with v prefix just in case
            res = vim.fn.system({ cfg.bin_path, '--validate', 'v' .. cfg.ttyimg_version })
            exit = vim.v.shell_error
        end
        local flat = res:gsub('\n',' ')
        -- Extract version substring heuristically
        local reported = flat:match("got:%s*'([^']+)'") or flat:match('got:?%s*([%w%._%-]+)') or ''
        local want = cfg.ttyimg_version
        local function norm(v) return (v or ''):gsub('^v','') end
        if exit == 0 then
          ok('ttyimg validate ok (version ' .. (reported ~= '' and reported or 'unknown') .. ')')
        else
          if norm(reported) == norm(want) and reported ~= '' then
            warn('ttyimg validate non-zero but version matches ('..reported..')')
          else
            warn('ttyimg validate failed output=' .. flat)
          end
        end
        -- Capability flags parsing (example: "Iterm: true, Kitty: true, Sixel: false")
        local iterm = flat:match('Iterm:%s*(%a+)')
        local kitty = flat:match('Kitty:%s*(%a+)')
        local sixel = flat:match('Sixel:%s*(%a+)')
        if iterm or kitty or sixel then
          ok(string.format('ttyimg capabilities iterm=%s kitty=%s sixel=%s', tostring(iterm), tostring(kitty), tostring(sixel)))
        end
      end
    end
  elseif cfg.engine == 'wezterm' then
    if vim.fn.executable('wezterm') == 1 then
      ok('wezterm executable present')
    else
      error_('wezterm engine selected but wezterm missing')
    end
  elseif cfg.engine == 'auto' then
    ok('auto-detect mode (resolved at display time)')
  else
    ok('engine=' .. cfg.engine .. ' (no external dependency)')
  end
end

local function check_cache(cfg)
  start('Cache')
  if cfg.cache and cfg.cache.enabled then
    ok('enabled max_bytes=' .. tostring(cfg.cache.max_bytes))
  else
    warn('disabled')
  end
end

local function check_env()
  start('Environment')
  local term = os.getenv('TERM') or ''
  local term_prog = os.getenv('TERM_PROGRAM') or ''
  ok('TERM=' .. term)
  if term_prog ~= '' then ok('TERM_PROGRAM=' .. term_prog) end
  if term:match('kitty') then ok('kitty-like terminal detected') end
  if term_prog:lower():match('wezterm') then ok('WezTerm detected') end
end

local function check_window_size(cfg)
  start('Sizing')
  if cfg.window_size and cfg.window_size.spx and cfg.window_size.sc then
    local spx = cfg.window_size.spx.x .. 'x' .. cfg.window_size.spx.y
    local sc = cfg.window_size.sc.x .. 'x' .. cfg.window_size.sc.y
    ok('px=' .. spx .. ' cells=' .. sc)
  else
    warn('window_size not initialized yet (call setup earlier)')
  end
end

local function check_platform()
  start('Platform')
  local os_, arch = utils.get_os_arch()
  if os_ then ok('OS=' .. os_) else warn('OS unsupported for auto install') end
  if arch then ok('ARCH=' .. arch) else warn('ARCH unsupported for auto install') end
end

local function check_config(cfg)
  start('Config Core')
  ok('size=' .. tostring(cfg.size))
  ok('debounce_ms=' .. tostring(cfg.debounce_ms))
  ok('backend=' .. tostring(cfg.backend))
  ok('resizeMode=' .. tostring(cfg.resizeMode))
  ok('offset=' .. tostring(cfg.offset))
end

function M.check()
  local cfg = config_mod.get()
  start('neo-img')
  info('health schema v2')
  check_engine(cfg)
  check_platform()
  check_window_size(cfg)
  check_cache(cfg)
  check_env()
  check_config(cfg)
  start('Extensions')
  local count = 0
  for _ in pairs(cfg.supported_extensions) do count = count + 1 end
  ok('registered extensions=' .. count)
end

return M
