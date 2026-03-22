# ace-overseer

One command to provision a worktree, open a tmux window, and prepare an assignment for execution.

![ace-overseer demo](docs/demo/ace-overseer-getting-started.gif)

## Why ace-overseer

- Remove the setup loop of manually creating worktrees, tmux windows, and assignments.
- Start focused task execution from a single workflow entrypoint.
- Keep active task work visible in one dashboard with assignment and git state.
- Prune completed worktrees safely when work is truly finished.

## Works With

- `ace-git-worktree` for isolated task branches.
- `ace-tmux` for window/session lifecycle.
- `ace-assign` for assignment queue orchestration.
- `ace-task` for task metadata and lifecycle state.
- `ace-git` for repository status context.

## Agent Skills

Package-owned canonical skill:

- `as-overseer`

## Features

- Task-focused worktree provisioning with tmux bootstrap
- Assignment-aware work orchestration
- Table or JSON status dashboard for active task worktrees
- Safe prune flow with preview and explicit confirmation

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Guide](docs/usage.md)
- [Handbook Reference](docs/handbook.md)

Part of [ACE (Agentic Coding Environment)](https://github.com/cs3b/ace).
