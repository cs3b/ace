# ace-test-runner-e2e

Agent-executed end-to-end tests with reproducible sandboxes and structured reporting.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-test-runner-e2e demo](docs/demo/ace-test-runner-e2e-getting-started.gif)

`ace-test-runner-e2e` runs realistic workflow scenarios through coding agents so teams can validate behavior beyond unit and integration coverage while keeping execution reproducible and isolated from the working tree.

## Use Cases

**Validate real developer workflows end-to-end** - run package-level scenarios with `ace-test-e2e` to confirm instructions, tooling, and outputs behave correctly under agent execution.

**Run broad regression sweeps across packages** - use `ace-test-e2e-suite` for cross-package scenario orchestration with filtering by package, tags, and prior failures.

**Keep execution deterministic and reviewable** - execute in sandboxes with structured outputs that are easy to inspect and compare across runs.

**Support migration and documentation-heavy testing** - run TS-style scenario suites where each case carries explicit metadata and reproducible command flows.

## Works With

- **[ace-test](../ace-test)** and **[ace-test-runner](../ace-test-runner)** for fast package/unit loops outside E2E scenario execution.
- **`ace-assign` workflows** for batched E2E execution, retries, and assignment-driven orchestration.
- **Package-local `test/e2e/` suites** for TS scenario definitions and package-specific coverage.

## Features

- Agent-executed E2E scenario runs with structured reports.
- Reproducible sandbox setup and cleanup workflows.
- Scenario discovery and selective execution by package, scenario ID, and tags.
- Suite-level execution across packages with parallel controls.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- [`ace-test-runner-e2e` changelog](CHANGELOG.md)

## Agent Skills

Package-owned canonical skills:

- `as-e2e-run`
- `as-e2e-create`
- `as-e2e-review`
- `as-e2e-plan-changes`
- `as-e2e-rewrite`
- `as-e2e-fix`
- `as-e2e-manage`
- `as-e2e-setup-sandbox`

## Part of ACE

`ace-test-runner-e2e` is part of [ACE](../README.md) (Agentic Coding Environment).
