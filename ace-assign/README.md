# ace-assign

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

[![Gem Version](https://img.shields.io/gem/v/ace-assign.svg)](https://rubygems.org/gems/ace-assign)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Phase-based assignment queues for safe, resumable agent execution.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-assign demo](docs/demo/ace-assign-getting-started.gif)

`ace-assign` turns broad goals into explicit step queues with tracked state transitions, scoped execution, and durable reports. It is designed for long-running or multi-agent workflows where retries, audits, and deterministic progression matter as much as implementation speed.

## How It Works

1. Convert multi-step work into a phase queue with clear state transitions (`pending`, `in_progress`, `done`, `failed`).
2. Execute steps sequentially or fork subtrees for parallel agent work, with scoped status tracking at each stage.
3. Advance through the queue with report-backed progression, retrying or injecting fix steps when failures occur.

## Use Cases

**Run structured delivery loops** - convert multi-step work into a queue and drive it from `pending` to `done` with clear state transitions and report-backed advancement. Use `/as-assign-drive` to run the full loop or `/as-assign-start` to kick off a fresh assignment.

**Delegate deep subtrees safely** - mark fork-capable subtrees and run them through `/as-assign-recover-fork` while preserving orchestrator visibility, scoped status checks, and post-subtree guard review.

**Recover from failure without losing history** - keep failed-step lineage intact, inject targeted retries or fix steps, and continue execution with auditable failure evidence.

**Manage concurrent assignments** - pin or switch active assignments with explicit targeting ([`ace-assign --assignment <id>`](docs/usage.md)) so parallel work does not cross streams.

**Compose assignments from templates** - use `/as-assign-compose` and `/as-assign-prepare` to build assignment plans from reusable patterns, then pair with [ace-task](../ace-task) for task lifecycle, [ace-bundle](../ace-bundle) for context loading, and [ace-review](../ace-review) for quality checks.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)
