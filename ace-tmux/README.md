<div align="center">
  <h1> ACE - TMUX </h1>

  Composable tmux sessions from YAML presets, with window injection and shared control operations for active sessions.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-tmux"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-tmux.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

`ace-tmux` helps you standardize terminal workspaces with preset-driven sessions, reusable windows, nested pane layouts, runtime inspection, and a shared live-control surface for pane/session interaction. You can discover preset names with `--list-presets`, spin up a full workspace from a session preset, inspect the live tmux state with `list`, inject a focused window into an already-running tmux session, or use `send`/`capture`/`wait`/`attach`/`detach` as the public ACE tmux control contract.

## How It Works

1. Define session and window layouts in YAML presets stored in `.ace/tmux/` (project), `~/.ace/tmux/` (user), or gem defaults.
2. Run `ace-tmux start [PRESET]` to create a full session or `ace-tmux window [PRESET]` to inject a window into the current session. Use `ace-tmux start ... --name <session>` when you need multiple concurrent sessions from the same preset.
3. Use `ace-tmux list` to inspect panes in the current window, or widen the scope with `--all-panes`, `--windows`, or `--sessions`.
4. Use `ace-tmux send`, `capture`, `wait`, `attach`, and `detach` for shared live tmux interaction without dropping to raw `tmux`.
5. Presets are deep-merged through the config cascade, so project-level overrides layer cleanly on top of shared defaults.

## Use Cases

**Start or attach to a preset-backed session** - run `ace-tmux start [PRESET]` to create a session from YAML presets, or attach to an existing session with the same name, integrating panes for [ace-task](../ace-task) status, [ace-git](../ace-git) info, and editor windows. Add `--name` to reuse the preset under a different runtime session name.

**Inject windows into running sessions** - run `ace-tmux window [PRESET]` to add a new window from presets without recreating the current session, useful for spinning up focused tool or test panes on the fly.

**Inspect tmux state without raw tmux** - run `ace-tmux list` to inspect the current window’s panes, `ace-tmux list --windows` for the current session’s windows, or `ace-tmux list --sessions` for the tmux server view.

**Control tmux through a shared ACE contract** - run `ace-tmux send`, `capture`, `wait`, `attach`, and `detach` when higher-level ACE tools or operators need live pane/session control without re-implementing tmux wrappers.

**Compose nested pane layouts in YAML** - use `direction` and nested pane containers to model custom split trees beyond tmux built-in layouts, keeping workspace structure version-controlled alongside your project.

**Reuse presets through config cascade** - load project presets from `.ace/tmux/`, personal presets from `~/.ace/tmux/`, and gem defaults via `.ace-defaults/tmux/` with deep-merge behavior so teams share a baseline while individuals customize.

**Discover preset names cleanly** - run `ace-tmux --list-presets` with an optional `sessions`, `windows`, or `panes` filter when you need to inspect available presets without overloading the live-runtime `list` command.

**Orchestrate task-focused workspaces** - pair with [ace-overseer](../ace-overseer) and [ace-assign](../ace-assign) for assignment-driven worktree and tmux orchestration that spins up isolated workspaces per task.

## Testing

- `ace-test ace-tmux` runs deterministic fast-layer tests under `test/fast/`.
- `ace-test ace-tmux feat` runs deterministic feature tests when `test/feat/` coverage exists.
- `ace-test ace-tmux all` runs full package deterministic coverage.
- `ace-test-e2e ace-tmux` runs retained workflow scenarios under `test/e2e/`.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
