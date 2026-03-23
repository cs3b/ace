# ace-tmux

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

[![Gem Version](https://img.shields.io/gem/v/ace-tmux.svg)](https://rubygems.org/gems/ace-tmux)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Composable tmux sessions from YAML presets, with window injection into active sessions.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-tmux demo](docs/demo/ace-tmux-getting-started.gif)

`ace-tmux` helps you standardize terminal workspaces with preset-driven sessions, reusable windows, and nested pane layouts. You can spin up a full workspace from a session preset or inject a focused window into an already-running tmux session.

## Use Cases

**Start or attach to a preset-backed session** - run `ace-tmux start [PRESET]` to create a session from YAML presets, or attach to an existing session with the same name.

**Inject windows into running sessions** - run `ace-tmux window [PRESET]` to add a new window from presets without recreating the current session.

**Compose nested pane layouts in YAML** - use `direction` and nested pane containers to model custom split trees beyond tmux built-in layouts.

**Reuse presets through config cascade** - load project presets from `.ace/tmux/`, personal presets from `~/.ace/tmux/`, and gem defaults via `.ace-defaults/tmux/` with deep-merge behavior.

**Operate a focused command surface** - use only three commands: `start`, `window`, and `list`.

## Works With

- `ace-task` for task status and navigation panes.
- `ace-git` for repository status panes.
- `ace-overseer` for task-focused worktree + tmux orchestration.
- `ace-assign` for assignment-driven execution in tmux workspaces.

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Guide](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-tmux --help`

## Agent Skills

Package-owned canonical skills: none currently published for `ace-tmux`.

---

Part of [ACE](../README.md) (Agentic Coding Environment)
