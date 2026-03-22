---
doc-type: user
title: ace-tmux Getting Started
purpose: Tutorial for creating sessions and adding windows with ace-tmux.
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-tmux

## Prerequisites

- `tmux` installed and available on PATH
- ACE toolchain available in your repository shell

## Installation

Install from RubyGems: `gem install ace-tmux`.

Verify command availability: `mise exec -- ace-tmux --help`.

## Start Your First Session

Run: `mise exec -- ace-tmux start`.

`ace-tmux` resolves the default session preset from `defaults.session` in config.

## Add a Window to a Running Session

From inside tmux, run: `mise exec -- ace-tmux window`.

`ace-tmux` resolves the default window preset from `defaults.window` in config.

## Create a Custom Window Preset

Create `.ace/tmux/windows/cc.yml`:

```yaml
direction: horizontal
panes:
  - preset: claude
    size: "35%"
  - direction: vertical
    size: "30%"
    panes:
      - preset: nvim
      - commands:
          - ace-git status
  - commands:
      - ace-task list
    size: "35%"

```

Use it in a session or add it directly with `ace-tmux window cc`.


## Nested Layouts

`direction: horizontal` creates columns, `direction: vertical` creates rows, and children can be mixed recursively.


```text
┌────────────┬──────────┬──────────────┐
│            │  nvim .  │              │
│   claude   │──────────│  task list   │
│    35%     │ git stat │    35%       │
│            │   30%    │              │
└────────────┴──────────┴──────────────┘

```

## Common Commands

| Command | Purpose |
| --- | --- |
| `ace-tmux start [PRESET]` | Start or attach to a session preset |
| `ace-tmux window [PRESET]` | Add a window preset to a running session |
| `ace-tmux list` | Show available session/window/pane presets |

## Next steps

- Define project-level presets in `.ace/tmux/`.
- Override personal defaults in `~/.ace/tmux/`.
- See [Usage Guide](usage.md) for full command and config reference.
