---
doc-type: user
title: ace-overseer Usage
purpose: Full CLI reference for ace-overseer commands and options.
ace-docs:
  last-updated: 2026-08-30
  last-checked: 2026-08-30
---

# Usage

## Command Surface

- `ace-overseer work-on`
- `ace-overseer status`
- `ace-overseer prune`
- `ace-overseer projects`
- `ace-overseer agents`
- `ace-overseer prepare`
- `ace-overseer prompt`
- `ace-overseer review`
- `ace-overseer stop`

## `ace-overseer work-on`

Create or reuse task worktrees, open tmux windows, and prepare assignments.

Invocation: `ace-overseer work-on --task <task-ref>`.

Options:

- `--task`, `-t` (required for tmux): task reference(s); repeatable and comma-separated values supported
- `--preset`, `-p`: assignment preset name
- `--runtime`: `tmux` (default) or `lab`
- `--work`: existing Lab Work ID; required with `--runtime lab`
- `--agent`: configured Lab agent ID; required with `--runtime lab`
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
- `--runtime`: `tmux` (default) or `lab`
- `--project`: filter Lab Works by project
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
- `--runtime`: `tmux` (default) or `lab`; Lab accepts dry-run only and delegates destruction to the exact `lab work destroy WORK --confirm` command
- `--quiet`, `-q`: suppress non-essential output
- `--debug`, `-d`: show debug output
- `--help`, `-h`: show help

## Example Flows

Start task work: `ace-overseer work-on --task 8q4.t.umu.1`.

Check dashboard: `ace-overseer status`.

Preview then prune: `ace-overseer prune --dry-run`, then `ace-overseer prune --yes`.

## Lab Runtime

Lab commands are available only where `/usr/local/bin/lab` is installed. ACE
does not read Lab credentials and does not call Podman or Herdr directly.

- `ace-overseer projects`: list registered Lab projects.
- `ace-overseer agents`: list registered Lab agents and concurrency limits.
- `ace-overseer prepare --runtime lab --project PROJECT --source KIND:ID --work WORK --planner AGENT --title TITLE`: create a reviewed Work and its isolated worktree.
- `ace-overseer work-on --runtime lab --work WORK --agent AGENT`: reserve the agent, create or reuse its Herdr workspace, and dispatch it.
- `ace-overseer status --runtime lab [--project PROJECT] [--format table|json]`: show Lab Work state. Continuous status lives in each project Herdr session, so `--watch` is intentionally rejected for Lab.
- `ace-overseer prompt --work WORK --file PATH`: forward prompt text from a file to the Work pane. Piped stdin is also supported; prompt text is never passed as a process argument.
- `ace-overseer review --work WORK --pr NUMBER`: prepare an exact-head admin review checkout and pane.
- `ace-overseer stop --work WORK`: stop the assigned process without destroying Work state.
- `ace-overseer prune WORK... --runtime lab --dry-run`: preview exact Work destruction commands; rerun with `--yes` to delegate each destruction to Lab.

Example:

```bash
ace-overseer prepare --runtime lab --project nervus \
  --source nervus-thread:67611c0b-f44c-4ac4-ae4e-55773b175617 \
  --work W321 --planner admin-agy --title "Reviewed task title"
ace-overseer work-on --runtime lab --work W321 --agent builder-codex
ace-overseer prompt --work W321 --file .ace-local/prompts/W321.md
ace-overseer status --runtime lab --project nervus --format json
```

## Public Verification Paths

Use these user-visible checks when validating behavior end-to-end:

- Preset override path:

  1. `ace-overseer work-on --task <task-ref> --preset <preset-name>`
  2. `ace-git-worktree list` (confirm worktree exists for `<task-ref>`)
  3. `ace-overseer status --format json` (confirm the task appears with assignment/preset details)

- Idempotent rerun oracle:

  1. Run `ace-overseer work-on --task <task-ref>` twice
  2. Verify one task entry remains in `ace-overseer status --format json`
  3. Verify only one matching worktree exists in `ace-git-worktree list`

- Prune lifecycle minimal flow:

  1. `ace-task done <task-ref>`
  2. `ace-overseer prune --dry-run`
  3. `ace-overseer prune --yes`
  4. `ace-git-worktree list` to confirm removed vs retained task worktrees
  5. `ace-overseer prune --dry-run` to confirm no remaining safe candidates
