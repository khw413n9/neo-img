--- Misc integration helpers (currently oil.nvim preview override)
local M = {}
local utils = require "neo-img.utils"
local main_config = require "neo-img.config"

--- @return integer? win the first other win in the same tab
local function get_first_other_win()
  local current_win = vim.api.nvim_get_current_win()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local all_wins = vim.api.nvim_tabpage_list_wins(current_tab)

  for _, win in ipairs(all_wins) do
    if win ~= current_win then
      return win
    end
  end

  return nil -- No other windows found in the same tab
end

--- enables drawing supported_extensions instead of normal oil-preview
--- Override oil preview for supported image extensions to draw via Neo-Img
function M.setup_oil()
  local status_ok, oil = pcall(require, "oil.config")
  if not status_ok then return end

  if oil.preview_win ~= nil then
    local pre_dis_fn = oil.preview_win.disable_preview
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
      if pre_dis_fn then
        return pre_dis_fn(filepath)
      else
        return false
      end
    end
  end
  return false
end

return M
