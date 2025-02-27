local M = {}
local utils = require "neo-img.utils"
local main_config = require "neo-img.config"

local function get_first_other_win()
  local current_win = vim.api.nvim_get_current_win()
  local all_wins = vim.api.nvim_list_wins()

  for _, win in ipairs(all_wins) do
    if win ~= current_win then
      return win
    end
  end

  return nil -- No other windows found
end

function M.setup_oil()
  local status_ok, oil = pcall(require, "oil.config")
  if not status_ok then return end

  if oil.preview_win ~= nil then
    oil.preview_win.disable_preview = function(filepath)
      local ext = utils.get_extension(filepath)
      if main_config.get().supported_extensions[ext] then
        vim.schedule(function()
          local win = get_first_other_win()
          if not win then return end
          utils.display_image(filepath, win)
        end)
        return true
      end
    end
  end
  return false
end

return M
