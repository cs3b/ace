# ace-assign

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

[![Gem Version](https://img.shields.io/gem/v/ace-assign.svg)](https://rubygems.org/gems/ace-assign)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Drive phase-based assignment queues so agents can execute complex work safely and resumably.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-assign demo](docs/demo/ace-assign-getting-started.gif)

`ace-assign` turns broad goals into explicit step queues with tracked state transitions, scoped execution, and durable reports. It is designed for long-running or multi-agent workflows where retries, audits, and deterministic progression matter as much as implementation speed.

## Use Cases

**Run structured delivery loops** - convert multi-step work into a queue and drive it from `pending` to `done` with clear state transitions (`pending`, `in_progress`, `done`, `failed`) and report-backed advancement.

**Delegate deep subtrees safely** - mark fork-capable subtrees and run them through `fork-run` while preserving orchestrator visibility, scoped status checks, and post-subtree guard review.

**Recover from failure without losing history** - keep failed-step lineage intact, inject targeted retries or fix steps, and continue execution with auditable failure evidence.

**Manage concurrent assignments** - pin or switch active assignments with explicit targeting (`--assignment <id>` and `--assignment <id>@<step>`) so parallel work does not cross streams.

**Coordinate with adjacent ACE tools** - pair with [ace-task](../ace-task) for task lifecycle, [ace-bundle](../ace-bundle) for context loading, [ace-review](../ace-review) and [ace-test](../ace-test) for quality checks, and [ace-demo](../ace-demo) for reproducible demos.

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Guide](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- [Exit Codes](docs/exit-codes.md)
- [Fork Context Guide](handbook/guides/fork-context.g.md)

## Agent Skills

Package-owned canonical skills:

- `as-assign-compose`
- `as-assign-create`
- `as-assign-drive`
- `as-assign-prepare`
- `as-assign-recover-fork`
- `as-assign-run-in-batches`
- `as-assign-start`

---

Part of [ACE](../README.md) (Agentic Coding Environment)
