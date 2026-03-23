# ace-tmux

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

[![Gem Version](https://img.shields.io/gem/v/ace-tmux.svg)](https://rubygems.org/gems/ace-tmux)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Composable tmux sessions from YAML presets, with window injection into active sessions.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-tmux demo](docs/demo/ace-tmux-getting-started.gif)

`ace-tmux` helps you standardize terminal workspaces with preset-driven sessions, reusable windows, and nested pane layouts. You can spin up a full workspace from a session preset or inject a focused window into an already-running tmux session, with config cascade across project, user, and gem defaults.

## How It Works

1. Define session and window layouts in YAML presets stored in `.ace/tmux/` (project), `~/.ace/tmux/` (user), or gem defaults.
2. Run `ace-tmux start [PRESET]` to create a full session or `ace-tmux window [PRESET]` to inject a window into the current session.
3. Presets are deep-merged through the config cascade, so project-level overrides layer cleanly on top of shared defaults.

## Use Cases

**Start or attach to a preset-backed session** - run `ace-tmux start [PRESET]` to create a session from YAML presets, or attach to an existing session with the same name, integrating panes for [ace-task](../ace-task) status, [ace-git](../ace-git) info, and editor windows.

**Inject windows into running sessions** - run `ace-tmux window [PRESET]` to add a new window from presets without recreating the current session, useful for spinning up focused tool or test panes on the fly.

**Compose nested pane layouts in YAML** - use `direction` and nested pane containers to model custom split trees beyond tmux built-in layouts, keeping workspace structure version-controlled alongside your project.

**Reuse presets through config cascade** - load project presets from `.ace/tmux/`, personal presets from `~/.ace/tmux/`, and gem defaults via `.ace-defaults/tmux/` with deep-merge behavior so teams share a baseline while individuals customize.

**Orchestrate task-focused workspaces** - pair with [ace-overseer](../ace-overseer) and [ace-assign](../ace-assign) for assignment-driven worktree and tmux orchestration that spins up isolated workspaces per task.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)
