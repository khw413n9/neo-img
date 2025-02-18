<h1 align="center">Neo-Img</h1>  
<p align="center">A Neovim plugin for viewing images in the terminal.</p> 
<div align="center">
    
[![Static Badge](https://img.shields.io/badge/ttyimg-4676C6?logo=educative&logoColor=4676C6&label=built%20upon&labelColor=15161b)](https://github.com/Skardyy/ttyimg) ˙ [![Static Badge](https://img.shields.io/badge/neovim-3CA628?logo=neovim&logoColor=3CA628&label=built%20for&labelColor=15161b)](https://neovim.io) ˙ ![GitHub License](https://img.shields.io/github/license/Skardyy/neo-img?style=flat&labelColor=%2315161b&color=%23f74b00)
</div>

---
https://github.com/user-attachments/assets/f7c76789-d57f-437c-b4da-444eebb7eb20

## Features ✨  
- Automatically preview supported image files
- Oil.nvim preview support
- Caching

## Installation 🚀  

> uses [ttyimg](https://github.com/Skardyy/ttyimg)  
> you can install it in 2 ways:  
> * via `:NeoImg Install` **(recommended)**
> * globally via `go install github.com/Skardyy/ttyimg@latest`, make sure you have GOPATH in your path `export PATH="$HOME/go/bin:$PATH`

Using lazy.nvim:
```lua
return {
    'skardyy/neo-img',
    build = function()
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
> document files require 
><details>
>  <summary>Libreoffice</summary>
> 
>  ```txt
>    make sure its installed and in your path  
>    * in windows its called soffice and should be in C:\Program Files\LibreOffice\program 
>    * linux should add it to path automatically
>  ```
> </details>
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
