<div align="center">
  <h1> ACE - Git Worktree </h1>

  Task-aware git worktree management for isolated environments in one command.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-git-worktree"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-git-worktree.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

![ace-git-worktree demo](docs/demo/ace-git-worktree-getting-started.gif)

`ace-git-worktree` gives each task, PR, or branch its own workspace so you can move faster without carrying local state between changes. It handles naming, hooks, cleanup, and navigation with configurable conventions across the team.

## How It Works

1. Create an isolated worktree from a task ID, PR number, or branch name with one command.
2. Work inside the worktree with task metadata and status kept in sync automatically.
3. Clean up stale worktrees when done, with path resolution for seamless `cd` navigation.

## Use Cases

**Start task work in an isolated environment** - run [`ace-git-worktree`](docs/usage.md) with a task ID to create a linked worktree, update task status, and set up the branch. Use `/as-git-worktree-create` for the full agent-driven setup.

**Review pull requests in dedicated directories** - create a worktree from a PR number instead of switching branches in your main checkout, keeping review work cleanly separated.

**Manage worktree lifecycle across a team** - use `/as-git-worktree-manage` with configurable naming, hooks, upstream push, and draft-PR automation to standardize workflows across the team.

**Coordinate with git workflow tools** - pair with [ace-task](../ace-task) for task lookup and status updates, [ace-git](../ace-git) for repository context, and [ace-git-commit](../ace-git-commit) for scoped commits inside task worktrees.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)

