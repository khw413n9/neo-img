# neo-img  
A Neovim plugin for viewing images in the terminal.  

## Demo  

https://github.com/user-attachments/assets/f7c76789-d57f-437c-b4da-444eebb7eb20

## Features
- Automatically preview supported image files
- Oil.nvim preview support

## Installation  

> requires [ttyimg](https://github.com/Skardyy/ttyimg)  
> you can install it by doing `go install github.com/Skardyy/ttyimg`

Using lazy.nvim:
```lua
return {
    'skardyy/neo-img',
    config = function()
        require('neo-img').setup()
    end
}
```

## Usage
- Images will automatically preview when opening supported files
- Use `:NeoImgShow` to manually display the current file

## Configuration
```lua
require('neo-img').setup({
    supported_extensions = {
        ['png'] = true,
        ['jpg'] = true,
        ['jpeg'] = true,
        ['gif'] = true,
        ['webp'] = true
    },
    auto_open = true,   -- Automatically open images when buffer is loaded
    oil_preview = true, -- changes oil preview of images too
    backend = "auto",   -- kitty / iterm / sixel / auto (auto detects what is supported in your terminal)
    size = {            --scales the width, will maintain aspect ratio
      oil = 800,
      main = 1600
    },
    offset = { -- only x offset
      oil = 8,
      main = 15
    }
})
```

> adjust the offset and size to match your screen  
> default config is likely to not look good on your screen  
> also sixel support is experimental, it may be slow and look worser then the other options  
