<h1 align="center">Neo-Img</h1>  
<p align="center">🖼️ A Neovim plugin for viewing images in the terminal. 🖼️</p> 
<div align="center">
    
[![Static Badge](https://img.shields.io/badge/neovim-3CA628?logo=neovim&logoColor=3CA628&label=built%20for&labelColor=15161b)](https://neovim.io)
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
>    * window: its called soffice and should be in C:\Program Files\LibreOffice\program 
>    * linux: should be in the path automatically
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
  ----- Important ones -----
  window_size = "1920x1080", -- size of the window. in windows auto queries using windows api, linux in the TODO. see below how to get the size of window in linux
  size = "80%",              -- size of the image in percent
  center = true,             -- rather or not to center the image in the window
  ----- Important ones -----

  ----- Less Important -----
  auto_open = true,   -- Automatically open images when buffer is loaded
  oil_preview = true, -- changes oil preview of images too
  backend = "auto",   -- auto / kitty / iterm / sixel
  resizeMode = "Fit", -- Fit / Strech / Crop
  offset = "0x3"      -- that exmp is 0 cells offset x and 3 y. this options is irrelevant when centered
  ----- Less Important -----
})
```  

> [!Important]
> in order to get the size for the window_size option you can:  
> write printf "\033[14t" into your terminal  
> it should return something [4;<height>;<width>t  
> for windows it auto queries the size using the winodws api

