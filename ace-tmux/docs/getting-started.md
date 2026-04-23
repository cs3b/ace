---
doc-type: user
title: ace-tmux Getting Started
purpose: Tutorial for creating sessions and adding windows with ace-tmux.
ace-docs:
  last-updated: 2026-04-16
  last-checked: 2026-04-16
---

# Getting Started with ace-tmux

## Prerequisites

- `tmux` installed and available on PATH
- ACE toolchain available in your repository shell

## Installation

Install from RubyGems: `gem install ace-tmux`.

Verify command availability: `ace-tmux --help`.

## Start Your First Session

See available presets first with `ace-tmux --list-presets sessions`.

Run: `ace-tmux start`.

`ace-tmux` resolves the default session preset from `defaults.session` in config.

For parallel workspaces from the same preset, use a custom runtime session name:
`ace-tmux start default --detach --name review-sandbox`.

## Add a Window to a Running Session

From inside tmux, run: `ace-tmux window`.

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
| `ace-tmux --list-presets [TYPE]` | Show available preset names |
| `ace-tmux start [PRESET]` | Start or attach to a session preset |
| `ace-tmux window [PRESET]` | Add a window preset to a running session |
| `ace-tmux list` | Show live panes in the current window |
| `ace-tmux list --windows` | Show windows in the current session |

## Next steps

- Define project-level presets in `.ace/tmux/`.
- Override personal defaults in `~/.ace/tmux/`.
- Validate package tests with `ace-test ace-tmux` and `ace-test-e2e ace-tmux`.
- See [Usage Guide](usage.md) for full command and config reference.
