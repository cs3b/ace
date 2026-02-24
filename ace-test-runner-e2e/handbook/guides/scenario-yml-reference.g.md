---
guide-id: g-scenario-yml-reference
title: scenario.yml Reference
description: Complete schema reference for TS-format scenario configuration files
version: "2.0"
source: ace-test-runner-e2e
---

# scenario.yml Reference

## Overview

The `scenario.yml` file configures a TS-format E2E scenario.

Supported test definition format is standalone pairs only:
- `TC-*.runner.md`
- `TC-*.verify.md`
- `runner.yml.md`
- `verifier.yml.md`

Legacy fields `mode` and `execution-model` are not supported.

## Location

```text
{package}/test/e2e/TS-{AREA}-{NNN}-{slug}/scenario.yml
```

Example: `ace-lint/test/e2e/TS-LINT-001-lint-pipeline/scenario.yml`

## Schema

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `test-id` | string | Unique test identifier in format `TS-{AREA}-{NNN}` |
| `title` | string | Human-readable scenario title |
| `area` | string | Functional area code |
| `package` | string | Package name |

### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `priority` | string | `medium` | Test priority: `high`, `medium`, `low` |
| `tool-under-test` | string | — | Primary command/tool validated |
| `sandbox-layout` | object | `{}` | Declared artifact paths and expected outputs |
| `duration` | string | — | Estimated duration (e.g., `~15min`) |
| `automation-candidate` | boolean | `false` | Whether test is automatable |
| `cost-tier` | string | `standard` | Run profile: `smoke`, `standard`, `deep` |
| `e2e-justification` | string | — | Why E2E is needed |
| `unit-coverage-reviewed` | array | `[]` | Unit/integration files reviewed |
| `requires` | object | — | Test prerequisites |
| `setup` | array | `[]` | Setup directives before execution |
| `last-verified` | string | — | Last successful verification date |
| `verified-by` | string | — | Agent that last verified |

## Standalone File Conventions

Scenario directory must contain:
- `runner.yml.md`
- `verifier.yml.md`
- paired `TC-*.runner.md` and `TC-*.verify.md`

Pairing rule:
- every `TC-XXX.runner.md` must have a matching `TC-XXX.verify.md`
- every `TC-XXX.verify.md` must have a matching `TC-XXX.runner.md`

Artifact layout conventions:
- canonical: `results/tc/{NN}/`
- avoid non-TC-scoped result folders

Canonical summary report fields:
- `tcs-passed`
- `tcs-failed`
- `tcs-total`
- `failed[].tc`

## `requires` Object

```yaml
requires:
  tools: [ace-lint, jq]
  ruby: ">= 3.0"
```

## `setup` Directives

Available directives:
- `copy-fixtures`
- `git-init`
- `env:`

Example:

```yaml
setup:
  - git-init
  - copy-fixtures
  - env:
      PROJECT_ROOT_PATH: "."
```

## Complete Example

```yaml
test-id: TS-LINT-001
title: Core Lint Pipeline
area: lint
package: ace-lint
priority: high
duration: ~10min
cost-tier: standard
e2e-justification: "Validates real subprocess behavior and report file generation"
unit-coverage-reviewed:
  - test/molecules/lint_runner_test.rb
  - test/organisms/lint_orchestrator_test.rb
tool-under-test: ace-lint
sandbox-layout:
  results/tc/01/: "help artifacts"
requires:
  tools: [ace-lint, standardrb, jq]
  ruby: ">= 3.0"
setup:
  - git-init
  - copy-fixtures
  - env:
      PROJECT_ROOT_PATH: "."
last-verified: 2026-02-24
verified-by: claude-opus-4
```

## Directory Structure

```text
test/e2e/TS-LINT-001-lint-pipeline/
├── scenario.yml
├── runner.yml.md
├── verifier.yml.md
├── TC-001-help-survey.runner.md
├── TC-001-help-survey.verify.md
└── fixtures/
```
