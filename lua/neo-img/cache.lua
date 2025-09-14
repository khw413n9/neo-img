--- Cache module for Neo-Img
--- Simple in-memory size bounded store (oldest timestamp eviction)
--- Key: geometry identity (filepath + spx + sc + scale + size)
--- Value: raw escape output

local profiler = require('neo-img.profiler')

local Cache = {
  total_bytes = 0,
  items = {},     -- key -> {data, bytes, ts}
  order = {},     -- array of {key, ts}
  counter = 0,
}

local function evict(max_bytes)
  if Cache.total_bytes <= max_bytes then return end
  table.sort(Cache.order, function(a,b) return a[2] < b[2] end)
  for _, pair in ipairs(Cache.order) do
    if Cache.total_bytes <= max_bytes then break end
    local k = pair[1]
    local it = Cache.items[k]
    if it then
      Cache.total_bytes = Cache.total_bytes - it.bytes
      Cache.items[k] = nil
    end
  end
  local new_order = {}
  for _, pair in ipairs(Cache.order) do
    if Cache.items[pair[1]] then table.insert(new_order, pair) end
  end
  Cache.order = new_order
end

--- Fetch data by key
---@param key string
---@param cfg NeoImg.Config
---@return string|nil
local function get(key, cfg)
  if not (cfg.cache and cfg.cache.enabled) then return nil end
  local it = Cache.items[key]
  if it then
    profiler.record('cache_hit', {bytes = it.bytes})
    Cache.counter = Cache.counter + 1
    it.ts = Cache.counter
    return it.data
  end
  return nil
end

--- Put data into cache (evicting if necessary)
---@param key string
---@param data string
---@param cfg NeoImg.Config
local function put(key, data, cfg)
  if not (cfg.cache and cfg.cache.enabled) then return end
  local bytes = #data
  if bytes > cfg.cache.max_bytes then return end
  local existing = Cache.items[key]
  if existing then Cache.total_bytes = Cache.total_bytes - existing.bytes end
  Cache.counter = Cache.counter + 1
  Cache.items[key] = {data = data, bytes = bytes, ts = Cache.counter}
  table.insert(Cache.order, {key, Cache.counter})
  Cache.total_bytes = Cache.total_bytes + bytes
  profiler.record('cache_store', {bytes = bytes, total = Cache.total_bytes})
  evict(cfg.cache.max_bytes)
end

local function stats()
  return {count = vim.tbl_count(Cache.items), total_bytes = Cache.total_bytes}
end

local function reset()
  Cache.total_bytes = 0
  Cache.items = {}
  Cache.order = {}
  Cache.counter = 0
end

return {
  get = get,
  put = put,
  stats = stats,
  reset = reset,
}
