local M = {}
local config = require('neo-img.config').get()

local echoraw = function(str)
  local win_height         = vim.api.nvim_win_get_height(0)
  local win_width          = vim.api.nvim_win_get_width(0)
  local win_top            = vim.fn.line('w0')

  local image_height_cells = math.floor(400 / 16)
  local image_width_cells  = math.floor(600 / 8)
  local row                = win_top + math.floor(win_height / 2) - math.floor(image_height_cells / 2)
  local col                = math.floor(win_width / 2) - math.floor(image_width_cells / 2)

  local move_cursor        = string.format("\27[%d;%dH", row, col)
  local full_str           = "\27[s" .. move_cursor .. str .. "\27[u"

  vim.fn.chansend(vim.v.stderr, full_str)
end

local get_extension = function(filename)
  return filename:match("^.+%.(.+)$")
end

local function build_command(filepath)
  if config.backend == "kitty" then
    return { "kitty", "+kitten", "icat", filepath }
  elseif config.backend == "magick" then
    return { "magick", filepath, "-resize", "600x400", "sixel:-" }
  end
end

local display_image = function(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    vim.notify("File not found: " .. filepath, vim.log.levels.ERROR)
    return
  end

  -- new buffer so gibbrish won't show and remove the echo
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_set_current_buf(buf)

  vim.api.nvim_command('mode')
  local command = build_command(filepath)
  vim.system(command, {}, function(obj)
    vim.schedule(function()
      echoraw(obj.stdout)
    end)
  end)
end

function M.setup_autocommands()
  local group = vim.api.nvim_create_augroup('NeoImg', { clear = true })

  if config.auto_open then
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      group = group,
      pattern = "*",
      callback = function()
        local filepath = vim.fn.expand('%:p')
        local ext = get_extension(filepath)

        if ext and config.supported_extensions[ext:lower()] then
          display_image(filepath)
        end
      end
    })

    -- adding oil.nvim preview support.
    -- maybe won't work if the user creates a new win manually, hence adding option to diable it
    if config.oil_preview then
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "oil://*",
        callback = function()
          local wins = vim.api.nvim_list_wins()
          local active_win = vim.api.nvim_get_current_win()

          if #wins > 1 then
            for _, win in ipairs(wins) do
              if win ~= active_win then
                local oil = require("oil")
                local entry = oil.get_cursor_entry()
                local dir = oil.get_current_dir()
                if entry ~= nil then
                  local filepath = dir .. entry.parsed_name
                  local ext = get_extension(filepath)

                  if ext and config.supported_extensions[ext:lower()] then
                    local buf_id = vim.api.nvim_win_get_buf(win)
                    vim.api.nvim_win_call(win, function()
                      vim.api.nvim_buf_set_option(buf_id, 'modified', false)
                      display_image(filepath)
                    end)
                  end
                end
                break
              end
            end
          end
        end,
      })
    end
  end

  -- Add command to manually trigger image display
  vim.api.nvim_create_user_command('NeoImgShow', function()
    local filepath = vim.fn.expand('%:p')
    M.display_image(filepath)
  end, {})
end

return M
