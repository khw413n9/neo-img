--- @class NeoImg.Autocommands
local M = {}
local utils = require "neo-img.utils"
local Image = require "neo-img.image"
local main_config = require "neo-img.config"
local others = require "neo-img.others"
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

    -- preview image on buf enter
    vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
        group = group,
        pattern = patterns,
        callback = function(ev)
            Image.StopJob()
            vim.schedule(function()
                local filepath = vim.api.nvim_buf_get_name(ev.buf)
                local win = vim.fn.bufwinid(ev.buf)
                utils.display_image(filepath, win)
            end)

            Image.StopJob()
            -- cancel previous pending draw
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
            timer:start(60, 0, function()
                vim.schedule(function()
                    -- revalidate just before drawing
                    local w = utils.win_of_buf(buf)
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
        end
    end, {
        nargs = 1,
        complete = function() return {'Install', 'DisplayImage'} end
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
