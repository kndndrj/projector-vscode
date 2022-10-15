# Neovim Projector VSCode Loader

Extension for [nvim-projector](https://github.com/kndndrj/nvim-projector) that
adds 2 additional loaders for:

- tasks.json
- launch.json

NOTE: Only basic functionality for now.

## tasks.json

- module: `tasksjson`
- options:
  - `path` - *string*: path to `tasks.json` - default: `./.vscode/tasks.json`
- variable expansion: VsCode like variables (e.g. `${file}`)

## launch.json

- module: `launchjson`
- options:
  - `path` - *string*: path to `launch.json` - default: `./.vscode/launch.json`
- variable expansion: VsCode like variables (e.g. `${file}`)
