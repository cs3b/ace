---
doc-type: user
title: ace-tmux
purpose: Landing page for composable tmux session management in ace-tmux.
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-tmux

Composable tmux session management via YAML presets -- add windows on the fly.

![ace-tmux demo](docs/demo/ace-tmux-getting-started.gif)

## Why ace-tmux

- Add a window preset to a running tmux session without restarting the session.
- Compose panes into windows and windows into sessions with deep-merge overrides.
- Build nested split trees in YAML beyond tmux built-in layout presets.
- Use project, user, and gem defaults together through the ACE config cascade.

## Works With

- `ace-task` for task status and navigation panes.
- `ace-git` for repository status panes.
- `ace-overseer` for task-focused worktree + tmux orchestration.
- `ace-assign` for assignment-driven execution in tmux workspaces.

## Agent Skills

Package-owned canonical skills: none currently published for `ace-tmux`.

## Features

- Dynamic window injection into active sessions
- Composable preset hierarchy (pane -> window -> session)
- Arbitrary nested layouts with predictable YAML structure
- Config cascade support across project, user, and gem defaults

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Guide](docs/usage.md)
- [Handbook Reference](docs/handbook.md)

## Installation

Install from RubyGems: `gem install ace-tmux`.

Part of [ACE (Agentic Coding Environment)](https://github.com/cs3b/ace).
