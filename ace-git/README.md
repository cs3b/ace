# ace-git

Git workflows and context commands for developers and AI agents.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-git demo](docs/demo/ace-git-getting-started.gif)

`ace-git` gives developers and coding agents focused git context commands and guided workflows that keep history
operations traceable, review-friendly, and safe to execute from the terminal.

## Use Cases

**Check repo and PR context without leaving the CLI** - inspect branch, change, and pull request state quickly before
running higher-risk history operations.

**Rebase with changelog-safe workflow guardrails** - run structured rebase flows that preserve package release metadata
and reduce manual conflict-prone steps.

**Prepare clean review history before publishing** - reorganize commit stacks and update PR metadata in a predictable
workflow sequence.

## Works With

- **[ace-git-commit](../ace-git-commit)** for scoped commit authoring and commit message workflows.
- **[ace-git-worktree](../ace-git-worktree)** for task-oriented worktree management around branch-level work.
- **[ace-bundle](../ace-bundle)** for loading workflow instructions and project/task context.

## Features

- Repository context commands for `status`, `diff`, `branch`, and `pr`.
- Changelog-preserving rebase workflow for versioned packages.
- PR create and update workflows with template support.
- Commit reorganization workflow for cleaner review history.
- Smart diff output with summary and grouped-stats formats.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-git --help`

## Agent Skills

Package-owned canonical skills:

- `as-git-rebase`
- `as-git-reorganize-commits`
- `as-github-pr-create`
- `as-github-pr-update`
- `as-github-release-publish`

## Part of ACE

`ace-git` is part of [ACE](../README.md) (Agentic Coding Environment).
