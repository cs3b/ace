# ace-git-commit

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

[![Gem Version](https://img.shields.io/gem/v/ace-git-commit.svg)](https://rubygems.org/gems/ace-git-commit)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Intention-aware conventional commit generation from diffs.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-git-commit demo](docs/demo/ace-git-commit-getting-started.gif)

`ace-git-commit` helps developers and coding agents turn repository changes into clear, scoped conventional commit messages while staying inside the terminal workflow. It analyzes diffs, supports intention hints, and handles monorepo scope-based splitting automatically.

## How It Works

1. Stage changes (by default) and analyze the diff to determine scope, type, and purpose.
2. Generate a conventional commit message using LLM analysis via [ace-llm](../ace-llm), optionally guided by an intention hint.
3. Create the commit, or split into multiple scope-based commits for monorepo change sets.

## Use Cases

**Generate high-quality commits from staged or unstaged changes** - run [`ace-git-commit`](docs/usage.md) to stage, analyze the diff, and produce a conventional commit message. Use `/as-git-commit` for the full agent-driven workflow.

**Guide message intent when diff context is not enough** - pass `-i "fix auth bug"` so the generated message reflects purpose, not only file deltas.

**Handle monorepo work without manual commit slicing** - commit path-scoped changes directly or rely on scope-aware splitting across packages with `--no-split` to override when needed.

**Preview and control commit behavior safely** - use `--dry-run` to preview, `--only-staged` for strict staging, or `-m` for explicit messages, with configuration cascade from [ace-support-config](../ace-support-config) for project and user overrides.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)
