<h1 align="center">ace-git</h1>

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-git"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-git.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

  Git workflows and context commands for developers and AI agents.
</p>

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)
> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

![ace-git demo](docs/demo/ace-git-getting-started.gif)

`ace-git` gives developers and coding agents focused git context commands and guided workflows that keep history operations traceable, review-friendly, and safe to execute from the terminal. It handles status, diff, branch, PR context, and structured rebase and reorganization flows.

## How It Works

1. Query repository state with context commands for status, diff, branch, and pull request metadata.
2. Run guided workflows for changelog-preserving rebases, commit reorganization, and PR creation or update.
3. Review results with smart diff output in summary and grouped-stats formats before publishing.

## Use Cases

**Check repo and PR context without leaving the CLI** - inspect branch, change, and pull request state quickly with [`ace-git`](docs/usage.md) before running higher-risk history operations.

**Rebase with changelog-safe workflow guardrails** - use `/as-git-rebase` to run structured rebase flows that preserve package release metadata and reduce manual conflict-prone steps.

**Prepare clean review history before publishing** - run `/as-git-reorganize-commits` to reorganize commit stacks, then use `/as-github-pr-create` or `/as-github-pr-update` to manage PR metadata in a predictable workflow sequence.

**Coordinate with commit and worktree tools** - pair with [ace-git-commit](../ace-git-commit) for scoped commit authoring, [ace-git-worktree](../ace-git-worktree) for task-oriented worktree management, and [ace-bundle](../ace-bundle) for loading workflow instructions.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)
