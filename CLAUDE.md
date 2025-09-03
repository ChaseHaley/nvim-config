# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Neovim configuration based on kickstart-modular.nvim, a fork of kickstart.nvim that uses a modular approach instead of a single file configuration. The configuration is organized into separate files for better maintainability.

## Architecture

### Core Structure
- **init.lua**: Entry point that loads utilities, options, keymaps, lazy plugin manager, and plugins
- **lua/options.lua**: Neovim options and settings (tabs, line numbers, clipboard, etc.)
- **lua/keymaps.lua**: Key mappings and autocommands
- **lua/utilities.lua**: Global utility functions (currently contains Windows detection)
- **lua/lazy-bootstrap.lua**: Lazy.nvim plugin manager bootstrap
- **lua/lazy-plugins.lua**: Plugin configuration loader

### Plugin Organization
- **lua/kickstart/plugins/**: Core kickstart plugins (gitsigns, telescope, lspconfig, etc.)
- **lua/custom/plugins/**: Custom plugin configurations organized as individual files
- Plugin loading uses `{ import = 'custom.plugins' }` to automatically load all files in the custom plugins directory

### Key Custom Plugins
- **copilot.lua**: GitHub Copilot integration with custom filetypes (typescript, cs, xml, csv only)
- **obsidian.lua**: Obsidian note-taking integration
- **oil.lua**: File manager
- **harpoon.lua**: File navigation
- **treesj.lua**: Code splitting/joining
- **vim-tmux-navigator.lua**: Tmux integration
- **multicursor.lua**: Multiple cursor support
- **crates.lua**: Rust crate management

## Development

### Code Formatting
- **Stylua** is configured via `.stylua.toml` with these settings:
  - Column width: 160
  - Unix line endings
  - Single quotes preferred
  - No call parentheses

### File Conventions  
- **Tab Settings**: Uses actual tabs (not spaces) with 4-space tab width
- **Indentation**: 4-space indentation for most files
- **Auto-formatting**: Web files (css, scss, js, ts, html, vue, jsx, tsx) use tabs with 4-space width

### Plugin Management
- **Plugin Manager**: Lazy.nvim
- **Plugin Commands**:
  - `:Lazy` - View plugin status
  - `:Lazy update` - Update plugins
  - `:Lazy` then `?` for help menu

### Key Features
- **Leader Key**: Space
- **Nerd Fonts**: Enabled (`vim.g.have_nerd_font = true`)
- **Clipboard**: Synced with OS
- **Line Numbers**: Both absolute and relative enabled
- **Text Wrapping**: Disabled by default
- **Folding**: Indent-based with level 99
- **Statusline**: Custom filename highlighting on buffer changes

### Platform Support
- **Cross-platform**: Includes Windows detection utility (`Is_Windows()`)
- **WSL/Linux**: Primary development environment
- **Tmux Integration**: Via vim-tmux-navigator plugin

### LSP and Completion
- **LSP**: Configured via kickstart lspconfig
- **Completion**: Blink-cmp for autocompletion
- **AI Assistance**: GitHub Copilot (selective filetypes only)
- **TypeScript**: typescript-tools.nvim for enhanced TS support
- **C#**: Roslyn LSP integration

### Testing and Linting
- **Linting**: Via kickstart lint plugin
- **Formatting**: Conform.nvim for code formatting
- **Health Checks**: `:checkhealth` for troubleshooting

## Important Notes

- This configuration is designed for users familiar with Vim/Neovim
- Many features require external dependencies (ripgrep, fd-find, language servers, etc.)
- Custom plugins are automatically loaded from `lua/custom/plugins/*.lua`
- Configuration emphasizes modularity and maintainability over single-file simplicity