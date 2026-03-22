---
doc-type: user
title: ace-tmux Usage
purpose: Full CLI and configuration reference for ace-tmux.
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Usage

## Command Surface

- `ace-tmux start [PRESET] [OPTIONS]`
- `ace-tmux window [PRESET] [OPTIONS]`
- `ace-tmux list [TYPE] [OPTIONS]`

`PRESET` is optional for `start` and `window` when defaults are configured.

## `ace-tmux start`

Create a tmux session from a session preset.

Examples:

- `ace-tmux start` uses `defaults.session`
- `ace-tmux start dev`
- `ace-tmux start dev --detach`
- `ace-tmux start dev --force`

Options:

- `--detach`, `-D`: do not attach after creation
- `--force`: kill existing session and recreate it
- `--root`, `-r`: override session working directory
- `--verbose`, `-v`: verbose output
- `--quiet`, `-q`: suppress non-essential output

Behavior notes:

- If session exists, `--force` is not set, and `--detach` is not set, `start` attaches to the existing session.
- If session exists, `--force` is not set, and `--detach` is set, `start` returns without attaching.
- If no preset is provided, `defaults.session` is used.

## `ace-tmux window`

Add a window preset to an existing tmux session.

Examples:

- `ace-tmux window` uses `defaults.window`
- `ace-tmux window cc`
- `ace-tmux window cc --session dev`
- `ace-tmux window cc --root ~/work/repo`

Options:

- `--name`, `-n`: override window name (default: basename of `--root`, then preset name)
- `--root`, `-r`: override window root directory
- `--session`, `-s`: target session name (required outside tmux)
- `--verbose`, `-v`: verbose output
- `--quiet`, `-q`: suppress non-essential output

Behavior notes:

- Inside tmux, current session is auto-detected.
- Outside tmux, provide `--session` (or set `ACE_TMUX_SESSION`).
- If no preset is provided, `defaults.window` is used.

## `ace-tmux list`

List available presets.

Examples:

- `ace-tmux list`
- `ace-tmux list sessions`
- `ace-tmux list windows`
- `ace-tmux list panes`

Arguments:

- `TYPE`: one of `sessions`, `windows`, `panes`

Options:

- `--verbose`, `-v`
- `--quiet`, `-q`

## Config Cascade

Preset/config loading order (highest priority first):

1. `.ace/tmux/`
2. `~/.ace/tmux/`
3. `.ace-defaults/tmux/` (from gem)

Matching preset names deep-merge from low to high priority.

## Configuration

### `config.yml`


```yaml
tmux_binary: tmux
defaults:
  session: default
  window: cc

```

Keys:

- `tmux_binary`: tmux executable path
- `defaults.session`: fallback session preset for `ace-tmux start`
- `defaults.window`: fallback window preset for `ace-tmux window`

### Session Presets (`sessions/*.yml`)

Common keys:

- `name` (required): session name
- `root`: base working directory
- `windows`: window entries or presets
- `startup_window`: startup target window name
- `attach`: preferred attach behavior for preset
- `tmux_options`: extra flags for `new-session`
- `pre_window`: command run in every pane before pane commands
- `on_project_start`: commands run before session creation
- `on_project_exit`: reserved key (not yet implemented by runtime)

### Window Presets (`windows/*.yml`)

Common keys:

- `name`: window name
- `layout`: built-in layout (`even-horizontal`, `even-vertical`, `main-horizontal`, `main-vertical`, `tiled`)
- `direction`: nested layout direction (`horizontal` or `vertical`)
- `root`: window root directory
- `panes`: pane entries or nested containers
- `pre_window`: pre-command run in each pane
- `options`: tmux window options

Nested layout mode is enabled when `direction` exists on the window or any child pane container.

### Pane Presets (`panes/*.yml`)

Common keys:

- `commands`: shell commands to send to pane
- `focus`: whether pane receives focus
- `root`: pane-specific root directory
- `name`: optional pane label
- `options`: tmux pane options

String shorthand is supported where a pane is expected:


```yaml
panes:
  - tail -f log/development.log

```

This expands to `commands: ["tail -f log/development.log"]`.

## Composition

Preset references use `preset:` and deep-merge local overrides on top.

Reuse a pane preset inside a window:

```yaml
# windows/dev.yml
panes:
  - preset: nvim
  - preset: nvim
    root: ~/other-project    # override merged on top
```

Reuse a window preset inside a session:

```yaml
# sessions/full.yml
windows:
  - preset: dev
  - preset: monitoring
    root: /var/log
```

Chained preset references are supported (depth-limited).

## Related Documentation

- [Getting Started](getting-started.md)
- [Handbook Reference](handbook.md)
