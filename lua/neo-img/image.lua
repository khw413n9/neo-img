local Image = {
  watch = {},
  draw = {},
  cache = {}
}
local tty = require("neo-img.tty")

Image.ns = vim.api.nvim_create_namespace("neo-img")

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

function Image.Should_Clean()
  for _, draw in pairs(Image.draw) do
    if draw then
      return true
    end
  end
  return false
end

function Image.Draw()
  local move_cursor = string.format("\27[%d;%dH", Image.row, Image.col)
  local image_esc   = "\27[s" .. move_cursor .. Image.esc .. "\27[u"
  tty.write(image_esc)
  Image.draw[Image.id] = true
end

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

function Image.Prepare()
  local buffers = Image.get_watch_list()
  for _, buf in ipairs(buffers) do
    Image.watch[buf] = 1
    vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
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

function Image.StopJob()
  if Image.job ~= nil then
    vim.fn.jobstop(Image.job)
    Image.job = nil
  end
end

function Image.Delete()
  if Image.Should_Clean() then
    vim.api.nvim_command("mode")
  end
  Image.StopJob()
end

return Image
