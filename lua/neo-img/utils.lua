---
--- Utility helpers for Neo-Img.
--- Responsibilities:
---  * window detection & validation (fast-event safe)
---  * dimension calculation & fallback size probing
---  * backend resolution
---  * drawing orchestration + job lifecycle guards
---  * (cache lives in separate module neo-img.cache)
---
--- Cache strategy:
---  key = filepath + geometry (spx/sc/scale/size/offset)
---  value = raw terminal escape sequence (sixel/kitty)
---  eviction: size-based; oldest timestamp first
---
--- @class NeoImg.Utils
local M = {}
local Image = require("neo-img.image")
local main_config = require("neo-img.config")
local profiler = require("neo-img.profiler")
local cache = require('neo-img.cache')

--- returns the os and arch
--- @return "windows"|"linux"|"darwin" os the OS of the machine
--- @return "386"|"amd64"|"arm"|"arm64" arch the arch of the cpu
function M.get_os_arch()
    local os_mapper = {
        Windows = "windows",
        Linux = "linux",
        OSX = "darwin",
        BSD = nil,
        POSIX = nil,
        Other = nil
    }

    local arch_mapper = {
        x86 = "386",
        x64 = "amd64",
        arm = "arm",
        arm64 = "arm64",
        arm64be = nil,
        ppc = nil,
        mips = nil,
        mipsel = nil,
        mips64 = nil,
        mips64el = nil,
        mips64r6 = nil,
        mips64r6el = nil
    }

    return os_mapper[jit.os], arch_mapper[jit.arch]
end

--- @class NeoImg.Size
--- @field x number
--- @field y number

--- returns a window size for fallback
--- @return {spx: NeoImg.Size, sc: NeoImg.Size}
--- Probe / approximate terminal pixel & cell size.
function M.get_window_size_fallback()
    local config = main_config.get()
    local os = M.get_os_arch()
    config.os = os
    local spx = {x = 1920, y = 1080}
    local sc = {x = vim.o.columns, y = vim.o.lines}
    if config.os ~= "windows" then
        local ffi = require("ffi")
        ffi.cdef [[
    struct winsize {
        unsigned short ws_row;
        unsigned short ws_col;
        unsigned short ws_xpixel;
        unsigned short ws_ypixel;
    };

    int ioctl(int fd, unsigned long request, void *arg);
    ]]
        local TIOCGWINSZ = config.os == "linux" and 0x5413 or 0x40087468
        local winsize = ffi.new("struct winsize")
        local success = ffi.C.ioctl(0, TIOCGWINSZ, winsize)
        if success == 0 then
            ---@diagnostic disable-next-line: undefined-field
            spx.x = winsize.ws_xpixel
            ---@diagnostic disable-next-line: undefined-field
            spx.y = winsize.ws_ypixel
        end
    end
    return {spx = spx, sc = sc}
end

--- Normalizes the size of the img
--- @return string value
local function get_scale_factor(value)
    local numberString = value:gsub("%%", "")
    local number = tonumber(numberString)
    if number > 95 then
        return 95 .. "%"
    else
        return value
    end
end

--- return a valid "normal" window for a buffer, or nil
--- @param buf integer buffer id
--- @return integer window id
--- Find a "normal" (non-floating, non-special) window showing buffer.
function M.win_of_buf(buf)
    buf = buf or 0
    -- NOTE: vim.fn.bufwinid() is a Vimscript function and may raise E5560
    -- (must not be called in a fast event context). To be safe in timer/libuv
    -- callbacks we re‑implement a lightweight search.
    local win = -1
    for _, w in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_buf(w) == buf then
            win = w
            break
        end
    end
    if win == -1 or win == 0 then return -1 end
    if not vim.api.nvim_win_is_valid(win) then return -1 end
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg and cfg.relative ~= "" then return -1 end
    -- Allow empty buftype (normal) and 'nofile' (we intentionally set this in lock_buf)
    local bt = vim.bo[buf].buftype
    if bt ~= "" and bt ~= "nofile" then return -1 end
    return win
end

function M.is_normal_win(win)
    if not win or win <= 0 then return false end
    if not vim.api.nvim_win_is_valid(win) then return false end
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg and cfg.relative ~= "" then return false end
    return true
end

--- Calculates dimensions for the image in the given win
--- @param win integer window id
--- @return {spx: string, sc: string, size: string, scale: string, offset: NeoImg.Size}
--- Compute geometric parameters used in ttyimg command and drawing.
function M.get_dims(win)
    local config = main_config.get()
    -- lazily initialize window_size if missing
    if not config.window_size then
        pcall(function()
            config.window_size = M.get_window_size_fallback()
        end)
        if not (config.window_size and config.window_size.spx and config.window_size.sc) then
            return {}
        end
    end

    -- local row, col = unpack(vim.api.nvim_win_get_position(win))

    win = win or M.win_of_buf(0)
    if not M.is_normal_win(win) then
        return {} -- window not ready -> skip quietly
    end
    local ok, pos = pcall(vim.api.nvim_win_get_position, win)
    if not ok or not pos then return {} end
    local row, col = pos[1], pos[2]
    local ovcol, ovrow = vim.o.columns - col, vim.o.lines - row

    -- getting factors
    local scale_factor = get_scale_factor(config.size)
    local win_factor_x = ovcol / vim.o.columns
    local win_factor_y = ovrow / vim.o.lines

    -- getting the offset
    local offsetx, offsety = 2, 3
    local tx, ty = config.offset:match("^(%d+)x(%d+)$")
    local offsetx_tmp, offsety_tmp = tonumber(tx), tonumber(ty)
    if offsetx_tmp then offsetx = offsetx_tmp end
    if offsety_tmp then offsety = offsety_tmp end

    -- getting size in px
    local spx = config.window_size.spx.x .. "x" .. config.window_size.spx.y
    if config.os ~= "windows" then spx = spx .. "xforce" end

    -- getting size in cells
    local sc = config.window_size.sc.x .. "x" .. config.window_size.sc.y ..
                   "xforce"

    -- getting the scale
    local scale = win_factor_x .. "x" .. win_factor_y

    return {
        spx = spx,
        sc = sc,
        size = scale_factor,
        scale = scale,
        offset = {x = col + offsetx, y = row + offsety}
    }
end

--- @param filename string the filename to get the ext from
--- @return string the ext
function M.get_extension(filename) return filename:match("^.+%.(.+)$") end

-- builds the command to run in order to get the img (handled by backend modules)
-- (LuaDoc removed here to avoid mis-association with following function)
-- backend resolver (initial simple: only ttyimg)
--- Resolve backend implementation module.
local function resolve_backend(config)
    -- engine selects implementation module; backend still controls protocol for ttyimg
    if config.engine == 'dummy' then
        local ok, mod = pcall(require, 'neo-img.backends.dummy')
        if ok then return mod end
    elseif config.engine == 'wezterm' then
        local ok, mod = pcall(require, 'neo-img.backends.wezterm')
        if ok then return mod end
    end
    return require('neo-img.backends.ttyimg')
end

--- @return integer? buf the main oil buf in the current tab
local function get_oil_buf()
    local current_tab = vim.api.nvim_get_current_tabpage()
    local all_wins = vim.api.nvim_tabpage_list_wins(current_tab)

    for _, win in ipairs(all_wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "oil" then return buf end
    end

    return nil
end

--- setup and draws the image
--- @param win integer the window id to listen on remove
--- @param row integer the starting row
--- @param col integer the starting col
--- @param output string the content of the image
--- @param filepath string the filepath to use as id
--- Create + prepare + draw image using Image module.
local function draw_image(win, row, col, output, filepath)
    local config = main_config.get()
    local watch = config.oil_preview and {get_oil_buf()} or {}
    Image.Create(win, row, col, output, watch, filepath)
    Image.Prepare()
    Image.Draw()
end

--- draws the image
--- @param filepath string the image to draw
--- @param win integer the window id to draw on
--- Public display entrypoint.
--- Decides fast-path (cache) vs spawning external job.
function M.display_image(filepath, win)
    local config = main_config.get()

    -- checks before draw (only enforce ttyimg binary when ttyimg engine)
    if config.engine == 'ttyimg' and config.bin_path == "" then
        vim.notify("ttyimg isn't installed, call :NeoImg Install",
                   vim.log.levels.ERROR)
        return
    end
    if vim.fn.filereadable(filepath) == 0 then
        vim.notify("File not found: " .. filepath, vim.log.levels.ERROR)
        return
    end

    -- normalize window first
    if not M.is_normal_win(win) then
        win = M.win_of_buf(0)
    end
    local opts = M.get_dims(win)
    if not (opts and opts.spx and opts.sc and opts.scale and opts.size and opts.offset) then
        return -- window/layout not ready yet
    end

    -- Build identity key (geometry + file) excluding placement offset (so repositioning can reuse cache)
    local identity_key = table.concat({filepath, opts.spx, opts.sc, opts.scale, opts.size}, '::')
    local placement_key = identity_key .. '::' .. opts.offset.x .. '::' .. opts.offset.y
    Image.geometry_key = identity_key
    profiler.record('render_start', {key = identity_key, placement = placement_key})
    -- cache lookup (fully drawn output cache)
    local cached = cache.get(identity_key, config)
    if cached then
        -- Direct draw without spawning job (skip inflight handling)
        draw_image(win, opts.offset.y, opts.offset.x, cached, filepath)
        return
    end
    profiler.record('cache_miss', {key = identity_key})
    if Image.last_placement_key == placement_key and Image.inflight == false then
        -- already drawn with same parameters
        return
    end
    -- If a job is currently running for the exact same identity, skip starting another
    if Image.inflight and Image.last_placement_key == placement_key then
        return
    end
    -- postpone committing last_key until successful draw (avoid blocking when user switches early)

    local backend = resolve_backend(config)
    profiler.record('backend_resolved', {engine = config.engine, backend = backend.name})
    if backend.inline then
        -- inline backend returns escape sequence directly
        local esc = backend.build(filepath, {
            spx = opts.spx,
            sc = opts.sc,
            scale = opts.scale,
            width = opts.size,
            height = opts.size
        }, config)
    profiler.record('render_ready', {mode = 'inline'})
    cache.put(identity_key, esc, config)
        draw_image(win, opts.offset.y, opts.offset.x, esc, filepath)
    Image.last_placement_key = placement_key
    Image.last_key = placement_key -- backward compatibility during refactor
        Image.inflight = false
        return
    end

    local command, protocol = backend.build(filepath, {
            spx = opts.spx,
            sc = opts.sc,
            scale = opts.scale,
            width = opts.size,
            height = opts.size
        }, config)

        Image.Delete() -- clears previous image (will also reset inflight)
        Image.inflight = true
        -- Safe concat (defensive) in case any element became nil unexpectedly
        local ok_cmd, joined = pcall(function()
            if type(command) == 'table' then
                return table.concat(command, ' ')
            else
                return tostring(command)
            end
        end)
        profiler.record('job_start', {cmd = ok_cmd and joined or 'N/A'})
        Image.job = vim.fn.jobstart(command, {
            on_stdout = function(_, data)
                if data then
                    local output = table.concat(data, "\n")
                    -- error
                    if string.len(vim.inspect(data)) < 100 then
                        -- if empty probbs just stopjob
                        if output == "" then return end
                        profiler.record('render_error', {msg = output})
                        vim.notify("error: " .. output)
                        return
                    end
                    profiler.record('render_ready', {size = #output, mode = 'job'})
                    cache.put(identity_key, output, config)
                    draw_image(win, opts.offset.y, opts.offset.x, output, filepath)
                    -- mark placement only after a successful full draw
                    Image.last_placement_key = placement_key
                    Image.last_key = placement_key -- backward compatibility
                    Image.inflight = false
                end
            end,
            stdout_buffered = true
        })
end

--- make a buf empty and unwritable
function M.lock_buf(buf)
    -- make it empty and not saveable, dk if all things are needed
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(buf, "readonly", true)
end

return M
