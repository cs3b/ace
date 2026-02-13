# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.2] - 2026-02-13

### Fixed

- Pane startup race condition — `send-keys` commands now execute after `select-layout`, preventing resize artifacts in apps like nvim/LazyVim

### Changed

- Restored per-pane `sleep 0.15` in claude and nvim pane presets — shell-side sleep absorbs async resize signals that Ruby-side delay cannot

## [0.3.1] - 2026-02-13

### Fixed

- Per-leaf pane `root` overrides now apply in nested layouts — previously all nested panes used the window/session root
- `LayoutStringBuilder` pane ID assignment falls back to sequential index when `pane_ids` array is shorter than expected

## [0.3.0] - 2026-02-12

### Added

- Nested pane layouts with arbitrary tree structure via `direction` key in YAML presets
- `LayoutNode` model — tree node (leaf or container) for nested layout representation
- `LayoutStringBuilder` atom — pure function that generates tmux custom layout strings with CRC16 checksum from a `LayoutNode` tree
- `list_panes` and `display_message_target` commands in `TmuxCommandBuilder`
- `layout_tree` attribute and `nested_layout?` predicate on `Window` model
- Recursive preset resolution for nested containers in `PresetResolver`
- Nested pane setup flow in `SessionManager` and `WindowManager` — flat splits → list-panes → layout string → select-layout

## [0.2.0] - 2026-02-12

### Added

- Generic `options` hash on Window and Pane models — pass-through for any tmux option via `set-window-option` and `set-option -p`
- `--root`/`-r` flag on `ace-tmux window` command to set working directory for the new window and all its panes
- `set_window_option` and `set_pane_option` commands in TmuxCommandBuilder

### Changed

- Default session preset: 3-pane layout (claude left 40%, shell right-top, nvim right-bottom) with `main-vertical` layout and `main-pane-width` option
- Code-editor window preset: 3 equal vertical panes (claude | shell | nvim) with `even-horizontal` layout

## [0.1.0] - 2026-02-12

### Added

- Initial release of ace-support-tmux
- Composable tmux session management via YAML presets
- Deep-merge composition at session, window, and pane levels
- `ace-tmux start <session-preset>` — Create tmux session from YAML preset
- `ace-tmux window <window-preset>` — Add window to existing session from preset
- `ace-tmux list [sessions|windows|panes]` — List available presets
- ACE config cascade integration (project > user > gem defaults)
- tmuxinator-compatible YAML keys
