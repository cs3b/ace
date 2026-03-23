# ace-test-runner

AI-friendly test runner with smart grouping, failure analysis, and persistent reports.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-test-runner demo](docs/demo/ace-test-runner-getting-started.gif)

`ace-test-runner` streamlines test execution so both developers and coding agents can run focused checks quickly, diagnose failures with context, and retain searchable execution history.

## Use Cases

**Run package tests from anywhere in the monorepo** - execute a package by name without changing directories and keep outputs consistent across local and CI environments.

**Target exactly the scope you need** - run by test groups (`atoms`, `molecules`, `organisms`, `models`, `unit`, `integration`, `system`, `all`, `quick`) or direct `file` / `file:line` selectors.

**Speed up triage on broken builds** - use failure-oriented output and persisted reports to locate regressions and continue diagnosis without rerunning broad suites.

**Standardize execution while keeping strategy separate** - use `ace-test-runner` for execution and `ace-test` workflows for planning, review, and suite improvement.

## Works With

- **ACE monorepo packages (`ace-*`)** for cross-package execution from any working directory.
- **[ace-test](../ace-test)** for testing strategy, planning, and remediation workflows.
- **`ace-test-suite`** command for full-monorepo execution orchestration.

## Features

- Package-aware execution for monorepo workflows.
- Smart test-group support for common ACE test layers.
- Focused location targeting with explicit file and `file:line` inputs.
- Persistent, searchable run reports for historical debugging.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- [`ace-test-runner` changelog](CHANGELOG.md)

## Agent Skills

- No package-owned `as-*` skills are defined in `ace-test-runner`.
- Use `ace-test` workflows (`as-test-*`) for planning, coverage, and remediation guidance.

## Part of ACE

`ace-test-runner` is part of [ACE](../README.md) (Agentic Coding Environment).
