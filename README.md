# nvim-config

## Introduction

This is my Neovim configuration.
The main branch is a fork of [dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim) with lots of my own customization on top.
This branch, 0.12, is a new configuration hand-written (with lots of hand-copying and hand-pasting from main) using Neovim 0.12's native vim.pack for plugin management.
I've omitted some plugins used in the main feature and swapped out [ThePrimeagen/harpoon (v2)](https://github.com/ThePrimeagen/harpoon/tree/harpoon2)
with [cbochs/grapple](https://github.com/cbochs/grapple.nvim).

## Per-machine and per-project plugins

`lua/plugins.lua` is the manifest: one `loadout` entry per plugin config module, with when it
loads (`now`, `ft`, `event`, `startup`), whether it loads (`cond`, `vscode`, `opt_in`), its
`deps`, and its `group`. Plugin modules install with `require("loadout").add`, which takes the
same arguments as `vim.pack.add`.

`lua/local.lua` is gitignored and holds what is true for one machine. `.nvim.lua` in a
project root does the same for one project (`exrc` is on). They call
`require("loadout").machine()` and `require("loadout").project()` to turn entries or groups off
with `disable` and opt-in entries on with `enable`. A project's toggles reach only entries that
load after startup, because `now` entries load before `.nvim.lua` runs. Copy
`lua/local.example.lua` and `.nvim.example.lua` to start.

An entry that is off never loads, but `vim.pack` still installs every plugin in
`nvim-pack-lock.json`. An `opt_in` entry installs its plugins outside `vim.pack`, into
`site/pack/loadout/opt`, so only the machines that enable it download them.

## VS Code

The [vscode-neovim](https://github.com/vscode-neovim/vscode-neovim) extension sets
`vim.g.vscode` before `init.lua` runs. Inside VS Code only the entries marked `vscode = true`
load: motions, text objects and edits. VS Code draws the editor and does LSP, completion, git
and files itself. Entries that a project's `.nvim.lua` adds follow the same rule. A few options
and keymaps also check `vim.g.vscode`.
