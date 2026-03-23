<div align="center">
  <h1> ACE - Git Worktree </h1>

  Task-aware git worktree management for isolated environments in one command.

  <img src="https://raw.githubusercontent.com/cs3b/ace/main/docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-git-worktree"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-git-worktree.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-git-worktree demo](docs/demo/ace-git-worktree-getting-started.gif)

`ace-git-worktree` gives each task, PR, or branch its own workspace so you can move faster without carrying local state between changes. It handles naming, post-create hooks (commands run after worktree creation), cleanup, and navigation with configurable conventions across the team.

## How It Works

1. Create an isolated worktree from a task ID, PR number, or branch name with one command.
2. Work inside the worktree with task metadata and status kept in sync automatically.
3. Clean up stale worktrees when done, with path resolution for seamless `cd` navigation.

## Use Cases

**Start task work in an isolated environment** - run [`ace-git-worktree`](docs/usage.md) with a task ID to create a linked worktree, update task status, and set up the branch. Use the `as-git-worktree-create` agent workflow for guided setup.

**Review pull requests in dedicated directories** - create a worktree from a PR number instead of switching branches in your main checkout, keeping review work cleanly separated.

**Manage worktree lifecycle across a team** - use the `as-git-worktree-manage` workflow with configurable naming, hooks, upstream push, and draft-PR automation to standardize workflows across the team.

**Orchestrate parallel task work with ace-overseer** - pair with [ace-overseer](../ace-overseer) to spin up worktrees per task, drive agents in parallel, and prune finished worktrees automatically.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
