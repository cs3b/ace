# Ace::TestRunner

AI-friendly test runner with smart grouping, failure analysis, and persistent reports.

![ace-test-runner demo](docs/demo/ace-test-runner-getting-started.gif)

## Why

`ace-test-runner` streamlines test execution so both people and agents can read results quickly.

- It runs tests with progress output tuned for fast local and CI feedback.
- It supports smart grouping and targeted execution in one command.
- It captures failures with context so triage can start immediately.
- It keeps timestamped reports so regressions are easier to audit.

## Works With

- ACE monorepo packages (`ace-*`) via cross-package test execution
- `ace-test` for package-level runs and options
- `ace-test-suite` for monorepo-wide execution

## Agent Skills

- No package-owned `as-*` skills are defined in `ace-test-runner`.
- Use `ace-test` workflows (`as-test-*`) for planning, coverage, and remediation guidance.

## Features

- Package-aware execution: run any package from any working directory.
- Smart group execution: `atoms`, `molecules`, `organisms`, `models`, `unit`, `integration`, `system`, `all`, `quick`.
- Focused execution by explicit files and `file:line` locations.
- Persistent, searchable run reports for historical debugging.

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Reference](docs/usage.md)
- [Handbook](docs/handbook.md)
- [`ace-test-runner` changelog](CHANGELOG.md)

## Cross-Reference

For testing strategy guidance, use `ace-test` documentation.

## Part of ACE

This package is part of the ACE monorepo and follows ACE conventions.
