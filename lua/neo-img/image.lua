---
--- Runtime state & low-level rendering helpers.
--- Image module keeps ephemeral data for one active image at a time.
--- Lifecycle:
---  * Create() sets target win/pos + escape sequence
---  * Prepare() sets up BufLeave autocmd for cleanup
---  * Draw() writes escape sequence (sixel/kitty) to terminal
---  * Delete()/StopJob() handles cleanup & job cancellation
--- in-flight state is controlled from utils.display_image.
---
--- @class NeoImg.Image
local Image = {
  --- @type integer[]
  watch = {},
  --- @type table<string, boolean>
  draw = {},
  --- in-flight job marker
  inflight = false,
  --- last drawn identity key
  last_key = nil,
}
local tty = require("neo-img.tty")

--- image constructor
--- @param win integer the win to draw on
--- @param row integer starting row to draw on
--- @param col integer starting col to draw on
--- @param esc string the content to draw
--- @param watch integer[] bufs to listen for image cleanup
--- @param id string the id of the img to track if its still drawn
function Image.Create(win, row, col, esc, watch, id)
  Image.win = win
  Image.row = row
  Image.col = col
  Image.esc = esc
  Image.id = id

  for _, buf in ipairs(watch) do
    -- 2 should watch, 1 watching, 0 nothing
    if Image.watch[buf] ~= 1 then
      Image.watch[buf] = 2
    end
  end
end

--- @return boolean rather or not there is a image to delete
function Image.Should_Clean()
  for _, draw in pairs(Image.draw) do
    if draw then
      return true
    end
  end
  return false
end

--- draws the image
function Image.Draw()
  local move_cursor = string.format("\27[%d;%dH", Image.row, Image.col)
  local image_esc   = "\27[s" .. move_cursor .. Image.esc .. "\27[u"
  tty.write(image_esc)
  Image.draw[Image.id] = true
end

--- @return integer[] the buffers to watch for image cleanup
function Image.get_watch_list()
  local buffers = {}
  if vim.api.nvim_win_is_valid(Image.win) then
    table.insert(buffers, vim.api.nvim_win_get_buf(Image.win))
  end
  for bufnr, status in pairs(Image.watch) do
    if status == 2 then
      table.insert(buffers, bufnr)
    end
  end
  return buffers
end

--- prepares image cleanup
function Image.Prepare()
  local buffers = Image.get_watch_list()
  for _, buf in ipairs(buffers) do
    Image.watch[buf] = 1
    local group = vim.api.nvim_create_augroup("NeoImg", { clear = false })
    vim.api.nvim_create_autocmd({ "BufLeave" }, {
      group = group,
      buffer = buf,
      once = true,
      callback = function()
        if Image.watch[buf] == 1 then
          Image.Delete()
          Image.watch[buf] = 0
          Image.draw = {}
        end
      end,
      desc = "Delete image when window or buffer is no longer visible",
    })
  end
end

--- stops jobs to draw an image
--- Stop the external job (if any) and reset inflight flag.
function Image.StopJob()
  if Image.job ~= nil then
    vim.fn.jobstop(Image.job)
    Image.job = nil
  end
  Image.inflight = false
  -- Do not keep last_key if we aborted mid-job; allow re-render later
  -- (utils will set a new last_key upon successful completion only now)
end

--- cleans the screen if needed
--- Clear drawn image from screen (by forcing a mode refresh) & stop job.
function Image.Delete()
  if Image.Should_Clean() then
    vim.api.nvim_command("mode")
  end
  Image.StopJob()
end

return Image
