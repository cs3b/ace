---
doc-type: user
title: ace-git-worktree Getting Started
purpose: Tutorial for first-run ace-git-worktree workflows
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-git-worktree

This walkthrough shows the core `ace-git-worktree` loop: create an isolated task workspace, jump into it, inspect what
exists, and clean it up when the work is done.

## Prerequisites

* Ruby 3.2+
* Git 2.0+ or any modern Git with `git worktree` support
* `ace-git-worktree` installed
* Optional: `ace-task` for task metadata and status updates
* Optional: `mise` when your projects use `mise.toml` files that should be trusted automatically
* Optional: GitHub CLI (`gh`) for PR-based worktrees

## Installation

```bash
gem install ace-git-worktree
```

## 1. Create Your First Task Worktree

Start with a task-aware worktree:

```bash
ace-git-worktree create --task 081
```

This creates a separate worktree directory, derives a branch name from the task, and can update task metadata based on
your current worktree configuration.

## 2. Switch Into the Worktree

Resolve the path and enter it:

```bash
cd "$(ace-git-worktree switch 081)"
```

This keeps your shell history simple while avoiding hard-coded worktree paths.

## 3. Inspect Active Worktrees

List worktrees with task context when you want a quick overview:

```bash
ace-git-worktree list --show-tasks
```

Use `--search auth` or `--format json` later when you want filtering or machine-readable output.

## 4. Create a PR Worktree

Open a pull request in its own workspace:

```bash
ace-git-worktree create --pr 26
```

This is useful for review work, branch comparisons, or patching an existing PR without touching your current checkout.

## 5. Clean Up When You Finish

Remove the task worktree:

```bash
ace-git-worktree remove --task 081
```

Use `ace-git-worktree prune --dry-run` first when you want to preview stale-reference cleanup.

## Configuration Basics

Project overrides live in `.ace/git/worktree.yml`. User overrides live in `~/.ace/git/worktree.yml`. Start small:

```yaml
git:
  worktree:
    root_path: ".ace-wt"
    task:
      directory_format: "task.{task_id}"
      branch_format: "{id}-{slug}"
    cleanup:
      on_delete: true
```

Add hooks, auto-push, tmux launch, or PR automation only after the basic create/switch/remove loop feels right.

## Common Commands

| Goal | Command |
|------|---------|
| Create a task worktree | `ace-git-worktree create --task 081` |
| Create a PR worktree | `ace-git-worktree create --pr 26` |
| Switch into a worktree | `cd "$(ace-git-worktree switch 081)"` |
| List worktrees with task info | `ace-git-worktree list --show-tasks` |
| Remove a task worktree | `ace-git-worktree remove --task 081` |
| Preview stale cleanup | `ace-git-worktree prune --dry-run` |

## Next Steps

* Run `ace-git-worktree config --files` to see which config files are active
* Add `hooks.after_create` commands to trust `mise` or bootstrap dependencies
* Use `ace-git-worktree create --from origin/feature/name` for branch-based work
* Run `ace-git-worktree --help` to browse subcommand examples
