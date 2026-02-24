---
guide-id: g-scenario-yml-reference
title: scenario.yml Reference
description: Complete schema reference for TS-format scenario configuration files
version: "1.2"
source: ace-test-runner-e2e
---

# scenario.yml Reference

## Overview

The `scenario.yml` file is the configuration file for TS-format E2E test scenarios. It defines scenario metadata and setup directives that prepare the sandbox before test execution.

## Location

```
{package}/test/e2e/TS-{AREA}-{NNN}-{slug}/scenario.yml
```

Example: `ace-lint/test/e2e/TS-LINT-001-core-lint-pipeline/scenario.yml`

## Schema

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `test-id` | string | Unique test identifier in format `TS-{AREA}-{NNN}` |
| `title` | string | Human-readable scenario title |
| `area` | string | Functional area code (uppercase, e.g., LINT, REVIEW, NAV) |
| `package` | string | Package name (e.g., `ace-lint`, `ace-review`) |

### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `priority` | string | `medium` | Test priority: `high`, `medium`, or `low` |
| `mode` | string | `procedural` | Scenario mode: `procedural` or `goal` |
| `execution-model` | string | `isolated` | Goal-mode execution strategy: `isolated` or `sequential` |
| `tool-under-test` | string | — | Primary command/tool being validated |
| `sandbox-layout` | object | `{}` | Declared artifact paths and expected outputs |
| `duration` | string | — | Estimated duration (e.g., `~15min`) |
| `automation-candidate` | boolean | `false` | Whether this test could be automated |
| `cost-tier` | string | `standard` | Expected run cost profile: `smoke`, `standard`, or `deep` |
| `e2e-justification` | string | — | Why this scenario requires E2E instead of unit-only coverage |
| `unit-coverage-reviewed` | array | `[]` | Unit test files reviewed during Value Gate analysis |
| `requires` | object | — | Prerequisites for the test |
| `setup` | array | `[]` | Setup directives to execute before tests |
| `last-verified` | string | — | Date of last successful verification (YYYY-MM-DD) |
| `verified-by` | string | — | Agent that performed last verification |

### Goal-Mode File Conventions

When `mode: goal` is used:

- Inline goal mode uses `TC-*.tc.md` with per-TC frontmatter `mode: goal`
- Standalone goal mode uses paired files:
  - `TC-*.runner.md`
  - `TC-*.verify.md`
  - `runner.yml.md`
  - `verifier.yml.md`

Artifact layout conventions:
- Canonical: `results/tc/{NN}/`
- Legacy `results/{N}/` layout is deprecated and should not be authored in new scenarios

### `requires` Object

Defines prerequisites that must be met before running the test.

```yaml
requires:
  tools: [standardrb, rubocop, jq]  # CLI tools that must be available
  ruby: ">= 3.0"                    # Ruby version requirement
```

| Field | Type | Description |
|-------|------|-------------|
| `tools` | array | List of CLI tools that must be in PATH |
| `ruby` | string | Ruby version constraint |

### Balance Metadata

Use these fields to preserve E2E vs unit-test decision evidence:

```yaml
cost-tier: standard
e2e-justification: "Requires real tmux + git worktree side effects across CLI commands"
unit-coverage-reviewed:
  - test/commands/work_on_command_test.rb
  - test/organisms/work_on_orchestrator_test.rb
```

| Field | Type | Description |
|-------|------|-------------|
| `cost-tier` | string | Run profile: `smoke` (cheap), `standard` (default), `deep` (expensive) |
| `e2e-justification` | string | One-sentence reason this scenario needs real CLI/tools/filesystem |
| `unit-coverage-reviewed` | array | Repo-relative unit/integration test files checked for overlap |

### `setup` Directives

The `setup` array contains directives executed by `SetupExecutor` before the agent runs test cases.

#### `copy-fixtures`

Copies the `fixtures/` directory contents into the sandbox root.

```yaml
setup:
  - copy-fixtures
```

**Behavior:**
- Copies all files from `{scenario-dir}/fixtures/` to `{sandbox}/`
- Preserves directory structure
- Overwrites existing files with same name

**When to use:** When test cases need fixture files (test data, config files, etc.)

#### `git-init`

Initializes a git repository in the sandbox.

```yaml
setup:
  - git-init
```

**Behavior:**
- Runs `git init` in the sandbox directory
- Sets default user.email and user.name for commits
- Required for tools that depend on being in a git repository

**When to use:** When test cases invoke git commands or tools that require a git repository

#### `env:`

Sets environment variables for test execution.

```yaml
setup:
  - env:
      PROJECT_ROOT_PATH: "."
      CUSTOM_VAR: "value"
```

**Behavior:**
- Sets environment variables in the execution context
- Variables are available to all test cases in the scenario

**When to use:**
- Setting `PROJECT_ROOT_PATH: "."` when tests use ace-* commands that need project root
- Any environment-specific configuration

## Complete Example

```yaml
test-id: TS-LINT-001
title: Core Lint Pipeline
area: lint
package: ace-lint
priority: high
duration: ~10min
cost-tier: standard
e2e-justification: "Validates real StandardRB subprocess behavior and report file generation"
unit-coverage-reviewed:
  - test/molecules/lint_runner_test.rb
  - test/organisms/lint_orchestrator_test.rb
requires:
  tools: [ace-lint, standardrb, jq]
  ruby: ">= 3.0"

setup:
  - git-init
  - copy-fixtures
  - env:
      PROJECT_ROOT_PATH: "."

last-verified: 2026-02-11
verified-by: claude-opus-4
```

## Directory Structure

A complete TS-format scenario:

```
test/e2e/TS-LINT-001-core-lint-pipeline/
├── scenario.yml                    # This file
├── TC-001-valid-file-lint.tc.md    # Test case 1
├── TC-002-fix-mode.tc.md           # Test case 2
├── TC-003-error-handling.tc.md     # Test case 3
└── fixtures/                       # Shared test data
    ├── valid.rb
    ├── syntax_error.rb
    └── style_issues.rb
```

## Setup Execution Order

When multiple setup directives are specified, they execute in order:

1. `git-init` — Creates the git repository first
2. `copy-fixtures` — Copies fixtures into the initialized repo
3. `env:` — Sets environment variables (applied last, after filesystem is ready)

Example with all directives:

```yaml
setup:
  - git-init
  - copy-fixtures
  - env:
      PROJECT_ROOT_PATH: "."
```

## Verification Tracking

After successful test execution, update the verification fields:

```yaml
last-verified: 2026-02-11
verified-by: claude-opus-4
```

This helps track test freshness and identify tests that may need re-verification.

## Common Patterns

### Minimal Configuration

For simple scenarios that don't need git or fixtures:

```yaml
test-id: TS-REVIEW-001
title: Basic Review Operation
area: review
package: ace-review
```

### Taskflow-Aware Tests

For tests that use ace-taskflow or ace-git-worktree:

```yaml
test-id: TS-TASKFLOW-001
title: Worktree Creation
area: taskflow
package: ace-git-worktree

setup:
  - git-init
  - env:
      PROJECT_ROOT_PATH: "."
```

### Complex Fixture Setup

For scenarios with extensive test data:

```yaml
test-id: TS-DOCS-001
title: Documentation Generation
area: docs
package: ace-docs

setup:
  - git-init
  - copy-fixtures
  - env:
      PROJECT_ROOT_PATH: "."
```

## Validation

The scenario.yml is validated by `SetupExecutor` before execution. Common validation errors:

| Error | Cause | Fix |
|-------|-------|-----|
| `Missing required field: test-id` | test-id not specified | Add `test-id: TS-AREA-NNN` |
| `Invalid test-id format` | Wrong format | Use `TS-{AREA}-{NNN}` format |
| `Unknown setup directive` | Typo in directive | Use `copy-fixtures`, `git-init`, or `env:` |
| `fixtures/ not found` | copy-fixtures with no fixtures dir | Create `fixtures/` or remove directive |

## Related

- [E2E Testing Guide](e2e-testing.g.md) — Overview of E2E testing conventions
- [TC Authoring Guide](tc-authoring.g.md) — Writing test case files
- [scenario.yml Template](../templates/scenario.yml.template.yml) — Starting template
