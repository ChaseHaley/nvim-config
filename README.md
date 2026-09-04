# nvim-config

## Introduction

This is my Neovim configuration.
The main branch is a fork of [dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim) with lots of my own customization on top.
This branch, 0.12, is a new configuration hand-written (with lots of hand-copying and hand-pasting from main) using Neovim 0.12's native vim.pack for plugin management.
I've omitted some plugins used in the main feature and swapped out [ThePrimeagen/harpoon (v2)](https://github.com/ThePrimeagen/harpoon/tree/harpoon2)
with [cbochs/grapple](https://github.com/cbochs/grapple.nvim).

## Per-machine and per-project plugins

`lua/local.lua` is gitignored and holds what is true for one machine. `.nvim.lua` in a
project root does the same for one project (`exrc` is on). Both run before `later()` loads
anything, so both can turn plugins off with `require("lazyload").disable(name)`, where
`name` is a module or a bundle from `lazyload.bundles`. Copy `lua/local.example.lua` and
`.nvim.example.lua` to start.

A plugin that is off never loads. It is still installed, because `vim.pack` installs every
plugin in `nvim-pack-lock.json`.
