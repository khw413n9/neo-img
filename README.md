# neo-img 🖼️  
A Neovim plugin for viewing images in the terminal.  

## Demo 🎬  

https://github.com/user-attachments/assets/f7c76789-d57f-437c-b4da-444eebb7eb20

## Features ✨  
- Automatically preview supported image files
- Oil.nvim preview support

## Installation 🚀  

> uses [ttyimg](https://github.com/Skardyy/ttyimg)  
> the plugin will bundle it, just make sure to add the `build = "cd ttyimg && go build"`  
> but make sure you have [go](https://go.dev/) installed  

> you can install it globally as well: `go install github.com/Skardyy/ttyimg@latest`  
> make sure GOPATH is in your path `export PATH="$HOME/go/bin:$PATH`  

Using lazy.nvim:
```lua
return {
    'skardyy/neo-img',
    build = "cd ttyimg && go build",  -- build ttyimg
    config = function()
        require('neo-img').setup()
    end
}
```

## Usage 💼  
- Images will automatically preview when opening supported files
- Use `:NeoImgShow` to manually display the current file

## Configuration ⚙️  
```lua
require('neo-img').setup({
  supported_extensions = {
    ['png'] = true,
    ['jpg'] = true,
    ['jpeg'] = true,
    ['webp'] = true,
    ['svg'] = true,
    ['tiff'] = true
  },
  auto_open = true,             -- Automatically open images when buffer is loaded
  oil_preview = true,           -- changes oil preview of images too
  backend = "auto",             -- auto detect: kitty / iterm / sixel
  size = {                      --scales the width, will maintain aspect ratio
    oil = { x = 400, y = 400 }, -- a number (oil = 400) will set both at once
    main = { x = 800, y = 800 }
  },
  offset = {
    oil = { x = 5, y = 3 }, -- a number will only change the x
    main = { x = 10, y = 3 }
  },
  resizeMode = "Fit" -- Fit / Strech / Crop
})
```

> [!Important]
> adjust the offset and size to match your screen  
> default config is likely to not look good on your screen  
> also sixel support is experimental, it may be slow and look worser then the other options  
