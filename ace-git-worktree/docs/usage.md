---
doc-type: user
title: ace-git-worktree CLI Usage Reference
purpose: Command reference for ace-git-worktree
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-git-worktree CLI Usage Reference

Reference for `ace-git-worktree` commands, options, and configuration.

## Installation

```bash
gem install ace-git-worktree
```

## Command Overview

`ace-git-worktree` ships six commands:

* `create` for task-aware, PR-aware, and branch-based worktree creation
* `list` for active worktree inventory and filtering
* `switch` for resolving a worktree path you can `cd` into
* `remove` for safe worktree removal
* `prune` for stale-reference cleanup
* `config` for configuration inspection and validation

Run `ace-git-worktree --help` for the top-level summary and examples.

## Quick Start (5 Minutes)

Create a task worktree, list active worktrees, and resolve the path for shell navigation:

```bash
ace-git-worktree create --task 081
ace-git-worktree list --show-tasks
ace-git-worktree switch 081
```

**Expected output:**

```text
Created worktree for task 081
... task-associated worktree appears in list output ...
/path/to/project/.ace-wt/task.081
```

Success looks like a new worktree directory exists and `switch` returns a path you can `cd` into.

## Common Scenarios

### Scenario 1: Start Isolated Work on a Task

**Goal:** Create a task-specific workspace without touching your current checkout.

**Commands:**

```bash
ace-git-worktree create --task 081
ace-git-worktree list --show-tasks
```

**Expected output:**

```text
Created task worktree and branch for 081
... task.081 appears in the worktree list ...
```

**Next steps:** Run `cd "$(ace-git-worktree switch 081)"` to move into the new worktree.

### Scenario 2: Review a Pull Request in Its Own Worktree

**Goal:** Create a dedicated workspace for PR review or patching.

**Commands:**

```bash
ace-git-worktree create --pr 26
ace-git-worktree list
```

**Expected output:**

```text
Created PR worktree for #26
... ace-pr-26 appears in the worktree list ...
```

**Next steps:** Enter the PR worktree or remove it later with `ace-git-worktree remove pr-26`.

### Scenario 3: Clean Up Stale Worktrees Safely

**Goal:** See what cleanup would do before removing anything.

**Commands:**

```bash
ace-git-worktree prune --dry-run
ace-git-worktree remove --task 081 --dry-run
```

**Expected output:**

```text
Would prune stale references
Would remove task.081
```

**Next steps:** Re-run either command without `--dry-run` once the preview looks correct.

## Commands

### `ace-git-worktree create [BRANCH]`

Create a new worktree from a task, PR, explicit branch, or positional branch argument.

```bash
ace-git-worktree create --task 081
ace-git-worktree create --pr 123
ace-git-worktree create --from origin/feature/auth
ace-git-worktree create feature/new-auth
ace-git-worktree create --task 081 --dry-run
```

**Options:**

* `--task` - Task ID for a task-aware worktree
* `--pr`, `--pull-request` - PR number for a PR-aware worktree
* `--from`, `-b` - Create from a specific local or remote branch
* `--path` - Override the destination worktree path
* `--source` - Override the git ref used as the start point
* `--dry-run` - Show what would be created
* `--no-status-update` - Skip marking the task in progress
* `--no-commit` - Skip committing task metadata changes
* `--no-push` - Skip pushing task changes
* `--no-upstream` - Skip pushing the new branch with upstream tracking
* `--no-pr` - Skip automatic draft-PR creation when enabled
* `--push-remote` - Override the remote used for task-related pushes
* `--no-auto-navigate` - Stay in the current directory after creation
* `--commit-message` - Use a custom commit message for task metadata updates
* `--target-branch` - Override the PR target branch
* `--force` - Create even when the worktree already exists
* `-q`, `--quiet` - Suppress non-essential output
* `-v`, `--verbose` - Show verbose output
* `-d`, `--debug` - Show debug output

### `ace-git-worktree list`

List active worktrees with optional task metadata and filters.

```bash
ace-git-worktree list
ace-git-worktree list --show-tasks
ace-git-worktree list --format json
ace-git-worktree list --search auth
```

**Options:**

* `--format` - Output format: `table`, `json`, or `simple`
* `--show-tasks` - Include task associations
* `--task-associated` - Show only task-associated worktrees
* `--usable` - Show only usable worktrees
* `--search` - Filter by branch-name pattern
* `-q`, `--quiet` - Suppress non-essential output
* `-v`, `--verbose` - Show verbose output
* `-d`, `--debug` - Show debug output

### `ace-git-worktree switch [IDENTIFIER]`

Resolve a worktree path for shell navigation.

```bash
ace-git-worktree switch 081
ace-git-worktree switch feature-branch
ace-git-worktree switch --list
```

`IDENTIFIER` can be a task ID, branch name, directory name, or explicit path.

**Options:**

* `--list`, `-l` - List available worktrees instead of returning one path
* `-q`, `--quiet` - Suppress non-essential output
* `-v`, `--verbose` - Show verbose output
* `-d`, `--debug` - Show debug output

### `ace-git-worktree remove [IDENTIFIER]`

Remove a worktree by task, branch, directory, or path.

```bash
ace-git-worktree remove --task 081
ace-git-worktree remove feature-branch
ace-git-worktree remove --task 081 --force
ace-git-worktree remove --task 081 --dry-run
```

**Options:**

* `--task` - Remove the worktree for a specific task
* `--force` - Remove even with uncommitted changes
* `--keep-directory` - Keep the worktree directory after removal
* `--delete-branch`, `-D` - Also delete the associated branch
* `--dry-run` - Show what would be removed
* `-q`, `--quiet` - Suppress non-essential output
* `-v`, `--verbose` - Show verbose output
* `-d`, `--debug` - Show debug output

### `ace-git-worktree prune`

Prune deleted worktrees from git metadata and optionally remove orphaned directories.

```bash
ace-git-worktree prune
ace-git-worktree prune --dry-run
ace-git-worktree prune --cleanup-directories
```

**Options:**

* `--dry-run` - Preview what would be pruned
* `--cleanup-directories` - Remove orphaned worktree directories
* `--force` - Force cleanup
* `-q`, `--quiet` - Suppress non-essential output
* `-v`, `--verbose` - Show verbose output
* `-d`, `--debug` - Show debug output

### `ace-git-worktree config [SUBCOMMAND]`

Show current configuration, validate it, or list the config files in play.

```bash
ace-git-worktree config
ace-git-worktree config --show
ace-git-worktree config --validate
ace-git-worktree config --files
ace-git-worktree config validate
```

**Options:**

* `--show` - Show current configuration
* `--validate` - Validate configuration
* `--files` - Show configuration file locations
* `-q`, `--quiet` - Suppress non-essential output
* `-v`, `--verbose` - Show verbose output
* `-d`, `--debug` - Show debug output

## Configuration

`ace-git-worktree` uses the ACE configuration cascade:

* Project config: `.ace/git/worktree.yml`
* User config: `~/.ace/git/worktree.yml`
* Package defaults: `ace-git-worktree/.ace-defaults/git/worktree.yml`

### Common Settings

```yaml
git:
  worktree:
    root_path: ".ace-wt"
    auto_navigate: true
    tmux: false
    task:
      directory_format: "task.{task_id}"
      branch_format: "{id}-{slug}"
      auto_mark_in_progress: true
      auto_commit_task: true
      auto_push_task: true
      auto_setup_upstream: false
      auto_create_pr: false
    pr:
      directory_format: "ace-pr-{number}"
      branch_format: "pr-{number}-{slug}"
      fetch_before_create: true
    cleanup:
      on_delete: true
```

The defaults file also documents timeout controls, hook execution, current-task symlink creation, push remotes, and PR
title formatting.

## Troubleshooting

### Problem: `create --task` cannot find the task

**Symptom:** The command reports that the task does not exist.

**Solution:**

```bash
ace-task show 081
```

Use a task reference that exists in the current repository, or run the command from the project root where the ACE task
data is available.

### Problem: PR worktree creation fails

**Symptom:** `create --pr` reports a GitHub or authentication error.

**Solution:**

```bash
gh auth status
gh auth login
```

PR-based creation depends on `gh` being installed and authenticated.

### Problem: `switch` returns nothing useful

**Symptom:** The identifier does not resolve to a worktree path.

**Solution:**

```bash
ace-git-worktree list --show-tasks
```

Confirm the identifier matches a task ID, branch name, directory name, or path shown in the current worktree list.

## Related Tools

* `ace-task` for task metadata and status updates
* `ace-git` for repository and PR context
* `ace-git-commit` for commits inside worktrees
* `ace-bundle` for loading worktree workflow instructions directly
