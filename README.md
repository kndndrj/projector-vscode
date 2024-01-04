# Neovim Projector VSCode Loader

Extension for [nvim-projector](https://github.com/kndndrj/nvim-projector) that
adds 2 additional loaders for `tasks.json` and `launch.json` files.

NOTE: Only basic functionality for now.

## Installation

Install it as any other plugin. and add the loaders to `projector`'s setup
function:

```lua
require("projector").setup {
  loaders = {
    require("projector_vscode").LaunchJsonLoader:new(),
    require("projector_vscode").TasksJsonLoader:new(),
    -- ... your other loaders
  },
  -- ... the rest of your config
}
```
