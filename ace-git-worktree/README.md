# ace-git-worktree

Task-aware git worktree management -- isolated environments in one command.

![ace-git-worktree demo](docs/demo/ace-git-worktree-getting-started-4x.gif)

## Why

`ace-git-worktree` gives each task, PR, or branch its own workspace so you can move faster without carrying local state
between changes:

* create an isolated worktree from a task, PR, or branch with one command
* keep task status and metadata in sync when you start focused work
* review pull requests in their own directories instead of reusing your main checkout
* standardize naming, hooks, cleanup, and navigation across a team

## Works With

* `ace-task` for task lookup and status updates
* `ace-git` for repository context before or after worktree operations
* `ace-git-commit` for scoped commits inside task worktrees

## Agent Skills

Package-owned canonical skills for worktree workflows:

* `as-git-worktree`
* `as-git-worktree-create`
* `as-git-worktree-manage`

## Features

* task-linked worktrees with optional status updates, metadata, and branch setup
* pull request worktrees for review and branch-based worktrees for ad hoc work
* configurable naming, hooks, upstream push, and draft-PR automation
* path resolution for `cd` workflows, plus cleanup commands for stale worktrees

## Documentation

* [Getting Started](docs/getting-started.md)
* [CLI Usage Reference](docs/usage.md)
* [Handbook Catalog](docs/handbook.md)
* Command help: `ace-git-worktree --help`

## Part of ACE

`ace-git-worktree` is part of [ACE][1]: CLI tools designed for developers and ready for agents.

[1]: https://github.com/cs3b/ace
