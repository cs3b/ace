# ace-git

Git workflows and context commands for developers and AI agents.

![ace-git demo](docs/demo/ace-git-getting-started.gif)

## Why

`ace-git` keeps the fast repo context you need close to the workflows you use to shape history safely:

* see branch, PR, and activity context without leaving the terminal
* inspect diffs with focused filters and summary formats
* run guided rebase and PR workflows with built-in guardrails
* reorganize commit history without losing the thread of a release

## Works With

* `ace-git-commit` for scoped commit creation
* `ace-git-worktree` for task-oriented worktrees
* `ace-bundle` and `ace-nav` for loading workflow instructions

## Agent Skills

Package-owned canonical skills for git workflows:

* `as-git-rebase`
* `as-git-reorganize-commits`
* `as-github-pr-create`
* `as-github-pr-update`
* `as-github-release-publish`

## Features

* repository context commands for `status`, `diff`, `branch`, and `pr`
* changelog-preserving rebase workflow for versioned packages
* PR create and update workflows with template support
* commit reorganization workflow for cleaner review history
* smart diff output with summary and grouped-stats formats

## Documentation

* [Getting Started](docs/getting-started.md)
* [CLI Usage Reference](docs/usage.md)
* [Handbook Catalog](docs/handbook.md)
* Command help: `ace-git --help`

## Part of ACE

`ace-git` is part of [ACE][1]: CLI tools designed for developers and ready for agents.

[1]: https://github.com/cs3b/ace
