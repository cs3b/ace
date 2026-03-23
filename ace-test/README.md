# ace-test

Testing documentation package for planning, reviewing, and improving test strategy across ACE projects.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

`ace-test` is the handbook and workflow package for testing in ACE. It centralizes strategy guides, workflow instructions, and skill entry points for agents and developers. Use `ace-test-runner` when you need to execute tests.

## Use Cases

**Plan test coverage before implementation starts** - use test planning workflows to map expected behavior, ownership, and verification checkpoints before writing code.

**Repair failing tests with a repeatable workflow** - follow structured failure triage and fix loops to isolate regressions quickly and restore green runs with evidence.

**Improve suite quality over time** - run coverage-gap and performance-audit workflows to identify weak spots, prioritize upgrades, and keep the fast loop healthy.

**Standardize review quality for test code** - apply dedicated test review workflows for mock quality, layering fit, and maintainability.

## Works With

- **[ace-test-runner](../ace-test-runner)** for package-level and monorepo test execution commands.
- **[ace-bundle](../ace-bundle)** for loading test guides and workflows via protocol URLs.
- **[ace-support-nav](../ace-support-nav)** for resolving protocol resources used by test documentation flows.

## Features

- Protocol-first access to test guidance (`guide://`, `wfi://`, `agent://`).
- Language-agnostic testing guidance across Ruby, Rust, JavaScript/Vue, Bun, and related stacks.
- Workflow-first coverage for planning, fixing, reviewing, optimization, and performance auditing.
- Canonical package-owned skill definitions for provider integrations.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- [`ace-test` changelog](CHANGELOG.md)

## Agent Skills

Package-owned canonical skills:

- `as-test-plan`
- `as-test-create-cases`
- `as-test-fix`
- `as-test-improve-coverage`
- `as-test-verify-suite`
- `as-test-optimize`
- `as-test-performance-audit`
- `as-test-review`

## Part of ACE

`ace-test` is part of [ACE](../README.md) (Agentic Coding Environment).
