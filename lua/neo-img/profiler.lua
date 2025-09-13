---
--- Lightweight instrumentation ring buffer.
--- Used only when config.debug = true to keep overhead negligible.
--- Add new stages sparingly; timeline aims to stay human-parsable.
---
local M = {}
local config = require('neo-img.config')

local state = {
  entries = {},
  max = 40,
}

local function now()
  return (vim.uv and vim.uv.hrtime and vim.uv.hrtime()/1e6)
    or (vim.loop and vim.loop.hrtime and vim.loop.hrtime()/1e6)
    or (vim.fn.reltimefloat(vim.fn.reltime()) * 1000)
end

--- Record an instrumentation point
--- @param stage string
--- @param data table|nil
--- Record a profiling stage entry (no-op if debug disabled)
function M.record(stage, data)
  if not config.get().debug then return end
  local ts = now()
  table.insert(state.entries, {t = ts, stage = stage, data = data or {}})
  if #state.entries > state.max then
    table.remove(state.entries, 1)
  end
end

--- Return a copy of entries
--- Return deep copy of current entries
function M.get_entries()
  return vim.deepcopy(state.entries)
end

--- Format timeline differences
--- Format entries into aligned human readable timeline lines
function M.format()
  local out = {}
  local prev = nil
  local first = nil
  for _, e in ipairs(state.entries) do
    if not first then first = e.t end
    local dt = prev and (e.t - prev.t) or 0
    local total = e.t - first
    table.insert(out, string.format("%6.1fms (+%5.1f) %-14s %s", total, dt, e.stage, vim.inspect(e.data)))
    prev = e
  end
  return out
end

return M