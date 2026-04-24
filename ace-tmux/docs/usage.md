---
doc-type: user
title: ace-tmux Usage
purpose: Full CLI and configuration reference for ace-tmux.
ace-docs:
  last-updated: 2026-04-24
  last-checked: 2026-04-24
---

# Usage

## Command Surface

- `ace-tmux start [PRESET] [OPTIONS]`
- `ace-tmux window [PRESET] [OPTIONS]`
- `ace-tmux list [OPTIONS]`
- `ace-tmux --list-presets [TYPE]`
- `ace-tmux send [OPTIONS]`
- `ace-tmux capture [OPTIONS]`
- `ace-tmux wait [OPTIONS]`
- `ace-tmux attach [OPTIONS]`
- `ace-tmux detach [OPTIONS]`

`PRESET` is optional for `start` and `window` when defaults are configured.

## `ace-tmux start`

Create a tmux session from a session preset.

Examples:

- `ace-tmux start` uses `defaults.session`
- `ace-tmux start dev`
- `ace-tmux start dev --detach`
- `ace-tmux start dev --detach --name qa-dev`
- `ace-tmux start dev --force`

Options:

- `--detach`, `-D`: do not attach after creation
- `--force`: kill existing session and recreate it
- `--name`, `-n`: override the runtime tmux session name
- `--root`, `-r`: override session working directory
- `--verbose`, `-v`: verbose output
- `--quiet`, `-q`: suppress non-essential output

Behavior notes:

- If session exists, `--force` is not set, and `--detach` is not set, `start` attaches to the existing session.
- If session exists, `--force` is not set, and `--detach` is set, `start` returns without attaching.
- `--name` changes the tmux session name used at runtime without changing which preset is loaded.
- If no preset is provided, `defaults.session` is used.

## `ace-tmux window`

Add a window preset to an existing tmux session.

Examples:

- `ace-tmux window` uses `defaults.window`
- `ace-tmux window cc`
- `ace-tmux window cc --session dev`
- `ace-tmux window cc --session dev` (outside tmux path)
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
- ACE-managed window names are normalized to `A-Z`, `a-z`, `0-9`, `_`, and `-`; other punctuation is replaced with `-`.

## `ace-tmux list`

List live tmux sessions, windows, or panes.

Examples:

- `ace-tmux list`
- `ace-tmux list --all-panes`
- `ace-tmux list --windows`
- `ace-tmux list --sessions`
- `ace-tmux list --session dev --window work`

Options:

- `--session`, `-s`: target session name
- `--window`, `-w`: target window name, index, or tmux window id (`@2`)
- `--all-panes`: list panes across the resolved session
- `--windows`: list windows in the resolved session
- `--sessions`: list all tmux sessions

Behavior notes:

- With no scope flags, `list` shows panes in the resolved current window.
- `--all-panes` expands from the current window to every window in the resolved session.
- `--windows` lists windows in the resolved session.
- `--sessions` lists tmux sessions and does not accept `--session` or `--window`.
- Runtime target resolution follows the same precedence as the control surface: explicit flags, then ACE tmux env vars, then live tmux context.

## `ace-tmux --list-presets`

List available tmux preset names.

Examples:

- `ace-tmux --list-presets`
- `ace-tmux --list-presets sessions`
- `ace-tmux --list-presets windows`

Arguments:

- `TYPE`: optional `sessions`, `windows`, or `panes`

## `ace-tmux send`

Send a submitted command, literal text, or bounded named keys to a target pane.

Examples:

- `ace-tmux send --pane %1 --cmd "bundle exec rake test"`
- `ace-tmux send --session dev --window work --pane 0 --cmd "ace-task status" --capture`
- `ace-tmux send --pane %8 --cmd "ping" --wait --capture 20`
- `ace-tmux send --pane %8 --cmd "Task context?" --wait agent --timeout 30 --capture`
- `ace-tmux send --pane .1 --msg "echo ready" --key Enter`
- `ace-tmux send --pane %1 --msg "echo ready" --key Enter`
- `ace-tmux send --pane %1 --key C-c`

Options:

- `--session`, `-s`: target session name
- `--window`, `-w`: target window name, index, or tmux window id (`@2`)
- `--pane`, `-p`: target pane id (`%8`), full pane target (`dev:work.1`), or current-window pane shorthand (`.1`)
- `--cmd`, `-c`: command text to send and submit with `Enter`
- `--msg`, `-m`: literal text chunk to send without `Enter`
- `--key`, `-k`: named key to send
- `--capture [lines[:wait]]`: capture recent pane output after sending; defaults to `40:2`
- `--wait [condition]`: wait after send; bare `--wait` defaults to `agent`
- `--pattern`: pattern to match when waiting for `output`
- `--timeout`, `-t`: wait timeout in seconds when `--wait` is used
- `--interval`, `-i`: wait polling interval in seconds when `--wait` is used
- `--quiet`, `-q`: suppress non-essential output

Behavior notes:

- Provide at least one of `--cmd`, `--msg`, or `--key`.
- Use either `--cmd` or `--msg`, not both.
- Repeated `--msg` values are sent in order, then any implicit `Enter` from `--cmd`, then repeated `--key` values in order.
- `--cmd` always appends one final `Enter`.
- Embedded newlines in `--cmd` or `--msg` remain literal text; they are not expanded into extra key presses.
- Named keys are intentionally bounded; unsupported raw tmux key syntax is rejected.
- Interactive CLI panes such as `codex`, `claude`, and `pi` get a brief automatic pause before the first submit `Enter` after text so the TUI sees a submit key instead of a paste burst.
- `--wait agent` blocks until a supported interactive CLI pane visibly changes and then settles; bare `--wait` is shorthand for that main send-and-wait flow.
- `send --wait output` compares against the pre-send pane tail, so existing visible matches do not satisfy the wait unless the pattern appears again after the send.
- Interactive CLI detection also covers panes launched through shell wrappers, so detached `fish -c codex` / similar panes still use the interactive send, wait, and capture path.
- When `--wait` and `--capture` are used together, ACE waits first and then captures from the same pane, so the printed tail reflects the settled post-response screen.
- Target resolution uses one precedence rule across the control surface: explicit flags, then ACE tmux env vars, then live tmux context.
- `--capture N` prints the visible bottom `N` rows for interactive CLI panes and a recent history tail for generic shell panes.
- Supported pane forms are `%8`, `dev:work.1`, `.1`, and bare `1`. `dev:work:1` is invalid; use `dev:work.1` instead.
- `.1` and bare `1` both resolve against the explicit or resolved current window.
- Window names may contain dots. ACE resolves pane shorthands through tmux window ids internally, so `--window ace-t.n1d --pane .3` remains valid.

## `ace-tmux capture`

Capture recent output from a tmux pane.

Examples:

- `ace-tmux capture --pane %1`
- `ace-tmux capture --pane %1 --lines 80`

Options:

- `--session`, `-s`: target session name
- `--window`, `-w`: target window name, index, or tmux window id (`@2`)
- `--pane`, `-p`: target pane id (`%8`), full pane target (`dev:work.1`), or current-window pane shorthand (`.1`)
- `--lines`, `-n`: number of recent lines to capture

Behavior notes:

- Capture is a live control-side pane-tail operation, not a generic read-side runtime inventory surface.
- `--lines N` captures the visible bottom `N` rows for interactive CLI panes such as `codex`, `claude`, and `pi`.
- Generic shell panes keep using a recent history tail instead of the current visible screen.
- Interactive CLI captures may include visible draft/composer text when it is on screen.
- Pane targeting follows the same rules as `send`: `%8`, `dev:work.1`, `.1`, or bare `1`.

## `ace-tmux wait`

Wait for a bounded tmux condition.

Examples:

- `ace-tmux wait --pane %1 --for output --pattern "Task context:"`
- `ace-tmux wait --pane %8 --for agent`
- `ace-tmux wait --session dev --for window-active --window work-fs`
- `ace-tmux wait --pane %1 --for pane-exited`

Options:

- `--for`, `-f`: one of `agent`, `output`, `window-exists`, `window-active`, `pane-exists`, `pane-exited`
- `--session`, `-s`: target session name
- `--window`, `-w`: target window name, index, or tmux window id (`@2`)
- `--pane`, `-p`: target pane id (`%8`), full pane target (`dev:work.1`), or current-window pane shorthand (`.1`)
- `--pattern`: output substring to match
- `--lines`, `-n`: number of lines to observe for `output` and `agent` waits
- `--timeout`, `-t`: timeout in seconds
- `--interval`, `-i`: polling interval in seconds
- `--quiet`, `-q`: suppress non-essential output

Behavior notes:

- `--for agent` waits for a supported interactive CLI pane such as `codex`, `claude`, or `pi` to become visibly idle/stable, including panes launched through wrapper shells.
- `--pattern` is required for `--for output`.
- `--for output` observes the last `--lines` lines of the target pane.
- `--for pane-exited` succeeds when the pane reports `pane_dead=1` or disappears entirely.
- Wait timeouts fail clearly; they do not silently fall through.
- Pane targeting follows the same rules as `send`: `%8`, `dev:work.1`, `.1`, or bare `1`.

## `ace-tmux attach`

Attach to a tmux session using the same shared target-resolution rules.

Examples:

- `ace-tmux attach --session dev`

## `ace-tmux detach`

Detach clients from a tmux session.

Examples:

- `ace-tmux detach --session dev`

Behavior notes:

- `detach` removes attached clients from the target session and is intended to replace raw `tmux detach-client -s ...` usage in ACE-owned flows.

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

## Boundary Notes

- `ace-tmux` control commands (`send`, `capture`, `wait`, `attach`, `detach`) define the live interaction surface.
- Read-side runtime inventory currently uses the shipped `ace-tmux list` surface. No additional shared read-side CLI follow-up is active today; any future consumer-driven expansion should start as a new task rather than reopening the archived `8r6.t.xeu` family.

## Testing Contract

- `ace-test ace-tmux` validates deterministic fast coverage in `test/fast/`.
- `ace-test ace-tmux feat` validates deterministic feature coverage in `test/feat/` when present.
- `ace-test ace-tmux all` validates full deterministic package coverage.
- `ace-test-e2e ace-tmux` runs workflow scenarios in `test/e2e/`.
