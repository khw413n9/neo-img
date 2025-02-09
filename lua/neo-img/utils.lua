local M = {}
local config = require('neo-img.config').get()

local function clear_window_region()
  vim.api.nvim_command('mode')
end

local function check_ttyimg()
  return vim.fn.executable("ttyimg") == 1 -- 1 means executable, 0 means not
end

local get_dims = function(win)
  local row, col = unpack(vim.api.nvim_win_get_position(win))
  local size     = config.size.main
  local offset   = config.offset.main
  if col ~= 0 then
    size = config.size.oil
    offset = config.offset.oil
  end

  local start_row    = row + offset.y
  local start_column = col + offset.x
  return size, start_row, start_column
end

local echoraw = function(str, start_row, start_column)
  local move_cursor = string.format("\27[%d;%dH", start_row, start_column)
  local full_str    = "\27[s" .. move_cursor .. str .. "\27[u"

  vim.fn.chansend(vim.v.stderr, full_str)
end

local get_extension = function(filename)
  return filename:match("^.+%.(.+)$")
end

local function build_command(filepath, size)
  local valid_configs = { iterm = true, kitty = true, sixel = true }
  -- add the resize mod -m
  -- and add the format mode, maybe going to need to bundle it to make that work
  if valid_configs[config.backend] then
    return { "ttyimg", "-w", size.x, "-h", size.y, '-f', 'sixel', "-p", config.backend, filepath }
  else
    return { "ttyimg", "-w", size.x, "-h", size.y, '-f', 'sixel', filepath }
  end
end

local display_image = function(filepath, win)
  if not check_ttyimg() then
    vim.notify("ttyimg isn't installed, can't show img")
    return
  end

  if vim.fn.filereadable(filepath) == 0 then
    vim.notify("File not found: " .. filepath, vim.log.levels.ERROR)
    return
  end

  local size, start_row, start_column = get_dims(win)

  -- new buffer so gibbrish won't show and remove the echo
  vim.api.nvim_win_call(win, function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_set_current_buf(buf)

    -- delete usless buf
    local prev_buf = vim.fn.bufnr('#')
    if prev_buf ~= -1 then
      vim.api.nvim_buf_delete(prev_buf, { force = true })
    end

    local augroup = vim.api.nvim_create_augroup("MyBufferGroup", { clear = true })
    vim.api.nvim_create_autocmd({ "WinScrolled", "BufHidden", "BufUnload" }, {
      buffer = buf,
      group = augroup,
      once = true,
      callback = function()
        clear_window_region()
      end,
    })
  end)

  local command = build_command(filepath, size)

  vim.fn.jobstart(command, {
    on_stdout = function(_, data)
      if data then
        local output = table.concat(data, "\n")
        vim.schedule(function()
          echoraw(output, start_row, start_column)
        end)
      end
    end,
    stdout_buffered = true
  })
end


function M.setup_autocommands()
  local group = vim.api.nvim_create_augroup('NeoImg', { clear = true })

  if config.auto_open then
    vim.api.nvim_create_autocmd({ "BufRead" }, {
      group = group,
      pattern = "*",
      callback = function()
        local filepath = vim.fn.expand('%:p')
        local ext = get_extension(filepath)

        if ext and config.supported_extensions[ext:lower()] then
          local win = vim.api.nvim_get_current_win()
          display_image(filepath, win)
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
                    display_image(filepath, win)
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
