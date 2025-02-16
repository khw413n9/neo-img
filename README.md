# neo-img 🖼️  
A Neovim plugin for viewing images in the terminal.  

## Demo 🎬  

https://github.com/user-attachments/assets/f7c76789-d57f-437c-b4da-444eebb7eb20

## Features ✨  
- Automatically preview supported image files
- Oil.nvim preview support
- Caching

## Installation 🚀  

> uses [ttyimg](https://github.com/Skardyy/ttyimg)  
> you can install it in 2 ways:  
1) run `:NeoImg Install` **(recommended)**, it will install a precompiled binary  
2) install it globally via go `go install github.com/Skardyy/ttyimg@latest`, make sure you have GOPATH in your path `export PATH="$HOME/go/bin:$PATH`

Using lazy.nvim:
```lua
return {
    'skardyy/neo-img',
      build = function() -- option: it calls :NeoImg Install, may fail in first install because the plugin isn't ready at build, mostly for updates
        require("neo-img").install()
      end,
    config = function()
        require('neo-img').setup()
    end
}
```

## Usage 💼  
- Images will automatically preview when opening supported files  
- Use `:NeoImg DisplayImage` to manually display the current file  
- you can also call `require("neo-img.utils").display_image(filepath, win)` to display the image in the given window  

## Configuration ⚙️  
> document type files currently rely on `libreoffice` to convert them into image  
> see [ttyimg](https://github.com/Skardyy/ttyimg) for more info on supported files and why  
```lua
require('neo-img').setup({
  supported_extensions = {
    ['png'] = true,
    ['jpg'] = true,
    ['jpeg'] = true,
    ['webp'] = true,
    ['svg'] = true,
    ['tiff'] = true,
    ['tif'] = true,
    ['docx'] = true,
    ['xlsx'] = true,
    ['pdf'] = true,
    ['pptx'] = true,
  },
  auto_open = true,   -- Automatically open images when buffer is loaded
  oil_preview = true, -- changes oil preview of images too
  backend = "auto",   -- auto / kitty / iterm / sixel
  size = { -- size in pixels
    x = 800,
    y = 800
  },
  offset = { -- offset in cells (rows / cols)
    x = 10,
    y = 3
  },
  resizeMode = "Fit" -- Fit / Strech / Crop
})
```  

> [!Important]
> adjust the offset and size to match your screen  
> default config is likely to not look good on your screen  
> also sixel support is experimental, it may be slow and look worser then the other options  
