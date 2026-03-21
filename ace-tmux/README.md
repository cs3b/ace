---
doc-type: user
title: ace-tmux
purpose: Documentation for ace-tmux/README.md
ace-docs:
  last-updated: 2026-02-14
  last-checked: 2026-03-21
---

# ace-tmux

Composable tmux session management via YAML presets.

## Why ace-tmux?

**Dynamic windows.** Add a window preset to a running session without restarting anything. `ace-tmux window code-editor` — done. No other tmux manager does this cleanly.

**Composable at every level.** Pane presets compose into window presets. Window presets compose into session presets. Each layer deep-merges on top of the last, so you define once and override where needed.

**Nested layouts.** Go beyond tmux's five built-in layouts. Define arbitrary splits — three columns where the middle one is split into rows — all in YAML.

```yaml
# .ace/tmux/windows/cc.yml
name: cc
direction: horizontal
panes:
  - preset: claude
    size: "35%"
  - direction: vertical
    size: "30%"
    panes:
      - preset: nvim
      - commands: [ace-git status]
  - commands: [ace-taskflow status]
    size: "35%"
```

```
┌────────────┬──────────┬──────────────┐
│            │  nvim .  │              │
│   claude   │──────────│  taskflow    │
│    35%     │ git stat │   status     │
│            │   30%    │    35%       │
└────────────┴──────────┴──────────────┘
```

## Quick Start

```bash
# Start a session
ace-tmux start dev

# Add a window to your current session
ace-tmux window cc [--root $path-to-your-worktree]
```

See [docs/usage.md](docs/usage.md) for complete configuration reference.

## Installation

```bash
gem install ace-tmux
```

## License

MIT
