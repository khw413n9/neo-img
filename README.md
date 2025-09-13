<h1 align="center">Neo-Img</h1>  
<p align="center">🖼️ A Neovim plugin for viewing images in the terminal. 🖼️</p> 
<p align="center"><em>This repository is a fork with caching, and backend abstraction enhancements.</em></p>
<div align="center">
    
[![Static Badge](https://img.shields.io/badge/neovim-1e2029?logo=neovim&logoColor=3CA628&label=built%20for&labelColor=15161b)](https://neovim.io)  
</div>

---
https://github.com/user-attachments/assets/f7c76789-d57f-437c-b4da-444eebb7eb20

## Features ✨  
- Automatically preview supported image files
- Oil.nvim preview support
- Caching
 - In-flight job suppression & configurable debounce
 - Backend abstraction (currently ttyimg, easily extensible)
 - Lightweight profiling timeline

## Installation 🚀  

> uses [ttyimg](https://github.com/Skardyy/ttyimg)  
> you can install it in 2 ways:  
> * via `:NeoImg Install` **(recommended)**
> * globally via `go install github.com/Skardyy/ttyimg@v1.0.5`, make sure you have GOPATH in your path `export PATH="$HOME/go/bin:$PATH`

Using lazy.nvim:
```lua
return {
    'skardyy/neo-img',
    build = ":NeoImg Install",
    config = function()
        require('neo-img').setup()
    end
}
```

## Usage 💼  
- Images will automatically preview when opening supported files  
- Use `:NeoImg DisplayImage` to manually display the current file  
- you can also call `require("neo-img.utils").display_image(filepath, win)` to display the image in the given window  
- `:NeoImg Debug` prints recent profiling timeline when `debug = true`  

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
    png = true,
    jpg = true,
    jpeg = true,
    tiff = true,
    tif = true,
    svg = true,
    webp = true,
    bmp = true,
    gif = true, -- static only
    docx = true,
    xlsx = true,
    pdf = true,
    pptx = true,
    odg = true,
    odp = true,
    ods = true,
    odt = true
  },

  ----- Important ones -----
  size = "80%",  -- size of the image in percent
  center = true, -- rather or not to center the image in the window
  ----- Important ones -----

  ----- Less Important -----
  auto_open = true,   -- Automatically open images when buffer is loaded
  oil_preview = true, -- changes oil preview of images too
  backend = "auto",   -- protocol hint (ttyimg only): auto / kitty / iterm / sixel
  engine  = "ttyimg", -- implementation: ttyimg / dummy / wezterm
  resizeMode = "Fit", -- Fit / Stretch / Crop
  offset = "2x3",     -- that exmp is 2 cells offset x and 3 y.
  ttyimg = "local",   -- local / global
  debug = false,       -- enable profiling events (:NeoImg Debug)
  debounce_ms = 60,    -- delay before launching render (0 = immediate)
  cache = {
    enabled = true,
    max_bytes = 4 * 1024 * 1024, -- output cache upper bound
  },
  ----- Less Important -----
})
```  

### Profiling Events
When `debug = true`, the plugin logs a ring-buffer of events. (Recent additions unify inline/job paths.)

| Event             | Meaning                                                   |
|-------------------|-----------------------------------------------------------|
| `event_start`     | BufWinEnter trigger received                              |
| `timer_fire`      | Debounce timer elapsed                                    |
| `render_start`    | Begin render attempt (identity key decided)               |
| `cache_hit`       | Cache used, external work skipped                         |
| `cache_miss`      | Not cached, need backend                                  |
| `backend_resolved`| Backend module chosen (`engine` + backend name)           |
| `job_start`       | External tool spawned (non-inline engines)                |
| `render_ready`    | Output ready (mode = inline | job)                        |
| `render_error`    | Backend produced an error output                          |
| `cache_store`     | Output stored in cache                                    |

Use `:NeoImg Debug` to print the recent timeline.

### Cache
The cache stores the raw terminal (sixel/kitty) output string keyed by image + geometry. 
Eviction is size-based (oldest first) when `total_bytes > max_bytes`.

Disable or tune:
```lua
require('neo-img').setup({
  cache = { enabled = false, max_bytes = 8 * 1024 * 1024 }
})
```

### Backend / Engine Abstraction
Backends (engines) live in `lua/neo-img/backends/`.

Concept split:
* `engine` => implementation module (e.g. `ttyimg`, `dummy`, `wezterm`)
* `backend` => protocol hint passed to ttyimg (`auto|kitty|iterm|sixel`)

Each engine currently implements either `build()` (oneshot) or returns inline output directly. (Planned: a unified `render()` and optional persistent process.)

Example descriptor:
```lua
return {
  name = 'example',
  persistent = false,
  inline = false,           -- if true: build() returns escape output directly
  protocols = { sixel = true },
  build = function(filepath, opts, config) -- oneshot form
    -- return {cmd_parts...}, protocol
  end,
}
```
Implemented engines:
| Engine  | Type     | Notes                           |
|---------|----------|---------------------------------|
| ttyimg  | external | Default; supports protocols     |
| dummy   | inline   | Dev/testing; colored placeholder|
| wezterm | external | Uses `wezterm imgcat` (imgcat)  |

Select with:
```lua
require('neo-img').setup({
  engine = 'wezterm', -- or 'dummy', 'ttyimg'
  backend = 'sixel',  -- still affects ttyimg protocol choice
})
```

### Performance Tuning Tips
| Scenario                          | Tweak                                      |
|----------------------------------|--------------------------------------------|
| Faster first paint               | Reduce `debounce_ms` (e.g. 30 or 0)        |
| Prevent CPU spikes on fast nav   | Keep small `debounce_ms` (10–30)           |
| Many revisits to same images     | Increase `cache.max_bytes`                 |
| Memory pressure                  | Lower `cache.max_bytes` or disable cache   |
| Investigate slowness             | Set `debug = true` and inspect timeline    |

