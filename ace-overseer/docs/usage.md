---
doc-type: user
title: ace-overseer Usage
purpose: Full CLI reference for ace-overseer commands and options.
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Usage

## Command Surface

- `ace-overseer work-on`
- `ace-overseer status`
- `ace-overseer prune`

## `ace-overseer work-on`

Create or reuse task worktrees, open tmux windows, and prepare assignments.

Invocation: `ace-overseer work-on --task <task-ref>`.

Options:

- `--task`, `-t` (required): task reference(s); repeatable and comma-separated values supported
- `--preset`, `-p`: assignment preset name
- `--quiet`, `-q`: suppress non-essential output
- `--debug`, `-d`: show debug output
- `--help`, `-h`: show help

Internally, `work-on` now routes assignment creation through `ace-assign create --task ...`, so direct `ace-assign` and `ace-overseer` task flows use the same preset expansion behavior.

## `ace-overseer status`

Show status for active task worktrees.

Invocation: `ace-overseer status [--format table|json] [--watch]`.

Options:

- `--format`: output format (`table`, `json`)
- `--watch`, `-w`: auto-refresh dashboard
- `--quiet`, `-q`: suppress non-essential output
- `--debug`, `-d`: show debug output
- `--help`, `-h`: show help

## `ace-overseer prune`

Remove stale or completed task worktrees.

Invocation: `ace-overseer prune [TARGETS] [OPTIONS]`.

Arguments:

- `TARGETS`: optional task refs or folder names to prune

Options:

- `--assignment`, `-a`: prune a specific assignment by ID
- `--force`, `-f`: force-remove unsafe worktrees
- `--yes`, `-y`: skip interactive confirmation
- `--dry-run`: list prune candidates only
- `--quiet`, `-q`: suppress non-essential output
- `--debug`, `-d`: show debug output
- `--help`, `-h`: show help

## Example Flows

Start task work: `ace-overseer work-on --task 8q4.t.umu.1`.

Check dashboard: `ace-overseer status`.

Preview then prune: `ace-overseer prune --dry-run`, then `ace-overseer prune --yes`.
