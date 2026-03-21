---
doc-type: user
title: Usage Guide
purpose: Documentation for ace-tmux/docs/usage.md
ace-docs:
  last-updated: 2026-02-14
  last-checked: 2026-03-21
---

# Usage Guide

## Commands

### ace-tmux start

Create a tmux session from a preset.

```bash
ace-tmux start <preset>           # Start and attach
ace-tmux start <preset> --detach  # Start without attaching
ace-tmux start <preset> --force   # Kill existing session and recreate
```

If the session already exists, `start` attaches to it (unless `--force`).

### ace-tmux window

Add a window to a running tmux session.

```bash
ace-tmux window <preset>                # Add to current session
ace-tmux window <preset> -s my-session  # Add to named session
ace-tmux window <preset> -r ~/projects  # Override working directory
```

Must be run from inside tmux (or use `-s` to specify target session).

### ace-tmux list

List available presets.

```bash
ace-tmux list            # All presets
ace-tmux list sessions   # Session presets only
ace-tmux list windows    # Window presets only
ace-tmux list panes      # Pane presets only
```

## Config Cascade

Presets are loaded from three locations, highest priority first:

```
.ace/tmux/          # Project-level (checked into repo)
~/.ace/tmux/        # User-level (personal defaults)
.ace-defaults/tmux/ # Gem defaults (shipped with package)
```

Each location has the same structure:

```
tmux/
  config.yml
  sessions/
    dev.yml
  windows/
    code-editor.yml
  panes/
    nvim.yml
```

Higher-priority presets override lower ones with the same name. This means you can override a gem default by placing a file with the same name in `.ace/tmux/` or `~/.ace/tmux/`.

## Configuration

### config.yml

Global settings.

```yaml
tmux_binary: tmux   # Path to tmux binary
```

### Session Presets

A session contains one or more windows.

```yaml
# sessions/dev.yml
name: dev
root: ~/projects/my-app
startup_window: editor
attach: true
tmux_options: "-f ~/.tmux.conf"
pre_window: "nvm use 18"
on_project_start:
  - docker compose up -d
on_project_exit:
  - docker compose down
windows:
  - name: editor
    preset: code-editor
    root: ./src
  - name: server
    preset: rails-server
  - name: logs
    panes:
      - tail -f log/development.log
```

| Key | Type | Description |
|-----|------|-------------|
| `name` | String | Session name (required) |
| `root` | String | Base working directory for all windows |
| `windows` | Array | Window configurations |
| `startup_window` | String | Window to focus after creation |
| `attach` | Boolean | Attach after creation (default: `true`) |
| `tmux_options` | String | Extra tmux flags (e.g., `-f ~/.tmux.conf`) |
| `pre_window` | String | Command to run in every pane before its own commands |
| `on_project_start` | Array | Shell commands to run before session creation |
| `on_project_exit` | Array | Shell commands to run on session exit |

### Window Presets

A window contains panes arranged in a layout.

#### Flat Layout

Uses tmux's built-in layouts.

```yaml
# windows/code-editor.yml
name: code-editor
layout: even-horizontal
root: ~/projects
pre_window: "nvm use 18"
options:
  main-pane-width: "40%"
panes:
  - preset: claude
  - commands: []
  - preset: vim-editor
```

Built-in layouts: `even-horizontal`, `even-vertical`, `main-horizontal`, `main-vertical`, `tiled`.

#### Nested Layout

Arbitrary split trees. Use `direction` to define how children are arranged.

```yaml
# windows/cc.yml
name: cc
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
      - ace-taskflow status
    size: "35%"
```

- `direction: horizontal` — children are placed side by side (columns)
- `direction: vertical` — children are stacked (rows)
- `size` — percentage (`"40%"`) or absolute cells (`"80"`)
- Children without `size` split remaining space evenly

Nesting is unlimited. A container can hold leaves, other containers, or a mix.

```yaml
# Deeply nested example
direction: horizontal
panes:
  - direction: vertical
    size: "50%"
    panes:
      - commands: [top-left]
      - direction: horizontal
        panes:
          - commands: [bottom-left-a]
          - commands: [bottom-left-b]
  - commands: [right-side]
```

```
┌──────────────┬──────────────┐
│   top-left   │              │
│──────────────│  right-side  │
│ bl-a  │ bl-b │              │
└───────┴──────┴──────────────┘
```

| Key | Type | Description |
|-----|------|-------------|
| `name` | String | Window name |
| `layout` | String | Built-in tmux layout (flat mode only) |
| `direction` | String | `horizontal` or `vertical` (nested mode) |
| `root` | String | Working directory |
| `panes` | Array | Pane entries (leaves or nested containers) |
| `pre_window` | String | Command to run in every pane |
| `focus` | Boolean | Focus this window after session creation |
| `options` | Hash | Raw tmux window options (via `set-window-option`) |

**Flat vs. nested detection:** If the window or any of its panes has a `direction` key, nested mode is used. Otherwise, flat mode applies. Existing flat presets work without changes.

### Pane Presets

A pane runs commands in a terminal.

```yaml
# panes/nvim.yml
commands:
  - nvim .
focus: true
```

```yaml
# panes/claude.yml
commands:
  - claude
```

| Key | Type | Description |
|-----|------|-------------|
| `commands` | Array | Commands to run in the pane |
| `focus` | Boolean | Focus this pane after window creation |
| `root` | String | Working directory (overrides window root) |
| `name` | String | Pane name |
| `options` | Hash | Raw tmux pane options (via `set-option -p`) |

**String shorthand:** Anywhere a pane is expected, a plain string is expanded to `{ commands: [string] }`:

```yaml
panes:
  - tail -f log/dev.log    # same as { commands: ["tail -f log/dev.log"] }
```

## Composition

### The preset: Key

Any pane or window entry can reference a preset by name. The preset is loaded and the remaining keys are deep-merged on top.

```yaml
# Window referencing a window preset + overriding root
- name: editor
  preset: code-editor
  root: ./src

# Pane referencing a pane preset + overriding focus
- preset: nvim
  focus: false
```

Presets can chain: a preset can itself reference another preset. Resolution depth is capped at 10 to guard against circular references.

### Composition Examples

**Pane preset used across windows:**

```yaml
# panes/nvim.yml
commands: [nvim .]
focus: true
```

```yaml
# windows/editor.yml
layout: main-vertical
panes:
  - preset: nvim          # reuse
  - commands: [bash]

# windows/review.yml
layout: even-horizontal
panes:
  - preset: nvim          # reuse
    focus: false           # override
  - commands: [gh pr view]
```

**Window presets used across sessions:**

```yaml
# sessions/dev.yml
windows:
  - preset: code-editor
  - preset: rails-server

# sessions/review.yml
windows:
  - preset: code-editor
    root: ./pr-checkout
  - name: pr
    panes:
      - commands: [gh pr diff]
```

**Nested layout with pane presets:**

```yaml
# windows/workspace.yml
direction: horizontal
panes:
  - preset: claude
    size: "40%"
  - direction: vertical
    panes:
      - preset: nvim
      - commands: [bash]
```

## Window Options

Pass any tmux option through to `set-window-option`:

```yaml
# windows/main.yml
name: main
layout: main-vertical
options:
  main-pane-width: "40%"
  automatic-rename: "off"
panes:
  - commands: [claude]
  - commands: [bash]
  - commands: [nvim .]
```

## Pane Options

Pass any tmux option through to `set-option -p`:

```yaml
panes:
  - commands: [tail -f log/production.log]
    options:
      remain-on-exit: "on"
```
