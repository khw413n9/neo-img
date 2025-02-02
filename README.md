# neo-img  
A Neovim plugin for viewing images in the terminal.  

## Demo  
https://github.com/user-attachments/assets/d784b594-4b4a-406b-94c5-0ebffd820c57


## Features
- Automatically preview supported image files
- Oil.nvim preview support

## Installation

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
    oil_preview = true, -- Oil preview support
    backend = "viu" -- chafa / viu / kitty
})
```

> \[!Note]
> Nvim currently doesn't support things like kitty graphic protocol or sixels. 
> so the images will be rendered using the lower half blocks (worse quality)  
> when nvim (if) will implement those protocols it will look great :)  
