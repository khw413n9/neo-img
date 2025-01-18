# neo-img

A Neovim plugin for viewing images in the terminal using viu.

## Features
- Automatically preview supported image files
- Floating window display
- Configurable window size and appearance
- Automatic viu installation if not present

## Installation

Using packer.nvim:
```lua
use {
    'yourusername/neo-img',
    config = function()
        require('neo-img').setup({
            -- Optional configuration
            window = {
                width = 0.8,
                height = 0.8,
                border = 'rounded'
            },
            auto_open = true
        })
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
    window = {
        width = 0.8,  -- Percentage of screen width
        height = 0.8, -- Percentage of screen height
        border = 'rounded'
    },
    auto_open = true  -- Automatically open images when buffer is loaded
})
```
