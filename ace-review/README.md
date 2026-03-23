# ace-review

Multi-model code review with preset-based analysis for PRs, tasks, and packages.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Feedback Workflow](docs/feedback-workflow.md) | [Handbook Reference](docs/handbook.md)

![ace-review demo](docs/demo/ace-review-getting-started.gif)

`ace-review` runs focused, repeatable reviews with configurable presets and parallel model execution. Findings are captured as feedback items with a verify -> apply -> resolve lifecycle so review outcomes stay actionable.

## Use Cases

**Review pull requests with consistent quality gates** - run preset-driven reviews over PR diffs and optionally integrate with GitHub feedback flows.

**Run multi-model analysis in parallel** - execute the same review prompt across multiple models, then synthesize overlapping and conflicting findings.

**Manage feedback as tracked work** - move findings through draft, verified, pending, resolved, and skipped states with explicit follow-up commands.

**Audit review history through session artifacts** - keep saved review sessions for traceability, comparison, and handoff across contributors.

## Works With

- `ace-bundle` for loading workflow and prompt context.
- `ace-git` for diffs, commit ranges, and PR metadata.
- `ace-llm` for provider abstraction and multi-model execution.
- `ace-task` for task-scoped review workflows.

## Features

- Multi-model review execution with synthesis.
- Preset-based review modes for code, security, docs, PRs, and custom checks.
- GitHub PR integration through `--pr` and optional comment publication.
- Feedback lifecycle commands for verification and application.
- Session artifacts for reproducible review records.

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Guide](docs/usage.md)
- [Feedback Workflow](docs/feedback-workflow.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-review --help`

## Agent Skills

Package-owned canonical skills:

- `as-review-run`
- `as-review-pr`
- `as-review-package`
- `as-review-apply-feedback`
- `as-review-verify-feedback`

## Part of ACE

`ace-review` is part of [ACE](../README.md) (Agentic Coding Environment).
