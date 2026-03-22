---
doc-type: user
title: ace-assign
purpose: Landing page for phase-based assignment queues in ace-assign.
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-assign

Phase-based assignment queues that give AI agents structured, resumable work.

![ace-assign demo](docs/demo/ace-assign-getting-started.gif)

## Why ace-assign

- Turn multi-step workflows into an explicit queue with status tracking.
- Keep execution deterministic with step states: `pending`, `in_progress`, `done`, `failed`.
- Preserve failed-step history so retries and recovery stay auditable.
- Scale complex work using hierarchical steps and scoped subtree execution.
- Delegate deep work safely with fork context while keeping orchestrator visibility.

## Works With

- `ace-task` for task lifecycle and behavioral specs.
- `ace-bundle` for loading project/task/workflow context.
- `ace-review` and `ace-test` for quality gates before release.
- `ace-demo` for reproducible docs demos.

## Agent Skills

Package-owned canonical skills:

- `as-assign-compose`
- `as-assign-create`
- `as-assign-drive`
- `as-assign-prepare`
- `as-assign-run-in-batches`
- `as-assign-start`

## Features

- Assignment creation from YAML specs
- Dynamic step injection during execution
- Hierarchical queue orchestration with parent/child completion
- Scoped execution with `--assignment <id>@<step>`
- Fork subtree orchestration via `fork-run`
- Explicit assignment selection and multi-assignment management

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Guide](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- [Exit Codes](docs/exit-codes.md)
- [Fork Context Guide](handbook/guides/fork-context.g.md)

Part of [ACE (Agentic Coding Environment)](https://github.com/cs3b/ace).
