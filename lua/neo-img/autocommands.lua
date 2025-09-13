---
--- Autocommand + user command wiring for Neo-Img.
--- Contains:
---  * BufRead   -> lock image buffers (avoid accidental edits / writes)
---  * BufWinEnter (debounced) -> trigger image preview render
---  * :NeoImg Install / DisplayImage / Debug
--- NOTE: We intentionally only use BufWinEnter to avoid duplicate triggers.
---
--- @class NeoImg.Autocommands
local M = {}
local utils = require "neo-img.utils"
local Image = require "neo-img.image"
local main_config = require "neo-img.config"
local others = require "neo-img.others"
local profiler = require "neo-img.profiler"
local uv = vim.uv or vim.loop
local timer
local lastkey

--- setups the main autocommands
local function setup_main(config)
    local patterns = {}
    for ext, _ in pairs(config.supported_extensions) do
        table.insert(patterns, "*." .. ext)
    end

    local group = vim.api.nvim_create_augroup("NeoImg", {clear = true})

    -- lock bufs on read
    vim.api.nvim_create_autocmd({"BufRead"}, {
        group = group,
        pattern = patterns,
        callback = function(ev) utils.lock_buf(ev.buf) end
    })

    -- Preview image on buffer window enter.
    -- (BufEnter removed previously to avoid duplicate render chains.)
    vim.api.nvim_create_autocmd({"BufWinEnter"}, {
        group = group,
        pattern = patterns,
        callback = function(ev)
            profiler.record('event_start', {buf = ev.buf}) -- instrumentation root
            -- NOTE: Immediate scheduled draw path disabled for now to eliminate
            -- duplicate job_start events. Leaving code commented for quick restore.
            -- Image.StopJob()
            -- vim.schedule(function()
            --     profiler.record('scheduled_start', {})
            --     local filepath = vim.api.nvim_buf_get_name(ev.buf)
            --     local win = vim.fn.bufwinid(ev.buf)
            --     utils.display_image(filepath, win)
            -- end)

            Image.StopJob()
            -- Cancel previous pending draw (typical debounce pattern)
            if timer then
                pcall(timer.stop, timer);
                pcall(timer.close, timer);
                timer = nil
            end
            local buf = ev.buf
            local filepath = vim.api.nvim_buf_get_name(buf)
            local win = utils.win_of_buf(buf)
            if not win or filepath == "" then return end
            local key = table.concat({buf, win, filepath}, "::")
            if key == lastkey then return end
            lastkey = key
            timer = uv.new_timer()
            timer:start(config.debounce_ms or 60, 0, function()
                profiler.record('timer_fire', {})
                vim.schedule(function()
                    -- revalidate just before drawing
                    local w = utils.win_of_buf(buf) -- re-validate window existence
                    if not w or w ~= win then return end
                    if vim.api.nvim_buf_get_name(buf) ~= filepath then
                        return
                    end
                    utils.display_image(filepath, win)
                end)
            end)
        end
    })
end

--- setups the api
local function setup_api()
    local config = main_config.get()
    vim.api.nvim_create_user_command('NeoImg', function(opts)
        local command_name = opts.args
        if command_name == 'Install' then
            print("Installing Ttyimg...")
            require("neo-img").install()
        elseif command_name == 'DisplayImage' then
            local buf = vim.api.nvim_get_current_buf()
            local buf_name = vim.api.nvim_buf_get_name(buf)
            local ext = utils.get_extension(buf_name)
            if ext and config.supported_extensions[ext:lower()] then
                local win = vim.fn.bufwinid(buf)
                utils.display_image(buf_name, win)
            else
                vim.notify("invalid path for image: " .. buf_name)
            end
        elseif command_name == 'Debug' then
            local profiler = require('neo-img.profiler')
            local lines = profiler.format()
            if #lines == 0 then
                print('NeoImg: no debug entries (enable config.debug)')
                return
            end
            print('NeoImg timeline:')
            for _, l in ipairs(lines) do print(l) end
        end
    end, {
        nargs = 1,
        complete = function() return {'Install', 'DisplayImage', 'Debug'} end
    })
end

--- setups all the autocommands for neo-img
function M.setup()
    local config = main_config.get()
    vim.g.zipPlugin_ext = "zip" -- showing image so no need for unzip
    if config.auto_open then setup_main(config) end
    if config.oil_preview then
        others.setup_oil() -- disables preview for files that im already showing image preview
    end
    setup_api()
end

return M
