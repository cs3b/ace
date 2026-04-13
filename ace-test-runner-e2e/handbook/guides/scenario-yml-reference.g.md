---
doc-type: guide
title: scenario.yml Reference
purpose: Complete schema reference for TS-format scenario configuration files
ace-docs:
  last-updated: 2026-03-18
  last-checked: 2026-03-21
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
| `timeout` | integer | — | Optional per-scenario execution timeout in seconds |
| `automation-candidate` | boolean | `false` | Whether test is automatable |
| `tags` | array | `[]` | Scenario tags for filtering with `--tags`/`--exclude-tags` (OR semantics) |
| `cost-tier` | string | `smoke` | Run profile: `smoke`, `happy-path`, `deep` |
| `e2e-justification` | string | — | Why E2E is needed |
| `unit-coverage-reviewed` | array | `[]` | Deterministic test files reviewed (`test/fast` and/or `test/feat`) |
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

Role contract:
- `runner.yml.md` + `TC-*.runner.md` are execution-only.
- `verifier.yml.md` + `TC-*.verify.md` are verification-only with impact-first checks.

## `requires` Object

```yaml
requires:
  tools: [ace-lint, jq]
  ruby: ">= 3.0"
```

## `setup` Directives

Available directives:
- `git-init` — Initialize git repository in sandbox
- `run:` — Execute a shell command (bash -lc; env vars are re-exported to protect against mise clobbering)
- `copy-fixtures` — Copy fixtures/ directory into sandbox
- `write-file:` — Write inline content to a file (`path:` + `content:`)
- `agent-env:` — Environment variables passed to the runner/verifier agent subprocess (not setup commands)
- `tmux-session` — Create a detached tmux session
  - String form: `tmux-session` (uses scenario-based naming)
  - Hash form: `tmux-session: { name-source: run-id }` (uses unique E2E run ID as session name)
  - Runner teardown removes the created session after test execution

Example:

```yaml
setup:
  - git-init
  - tmux-session:
      name-source: run-id
  - run: "cp $PROJECT_ROOT_PATH/mise.toml mise.toml && mise trust mise.toml"
  - copy-fixtures
  - run: git add -A && git commit -m "initial" --quiet
  - agent-env:
      PROJECT_ROOT_PATH: "."
```

Setup rules:
- Setup is fail-fast. Do not hide setup failures with `|| true`.
- Setup belongs in `scenario.yml` and fixtures, not in TC runner instructions.
- If setup fails (for example, missing `mise trust` support), stop scenario execution and report infrastructure failure.

## Complete Example

```yaml
test-id: TS-LINT-001
title: Core Lint Pipeline
area: lint
package: ace-lint
priority: high
duration: ~10min
cost-tier: smoke
tags: [smoke, "use-case:lint"]
e2e-justification: "Validates real subprocess behavior and report file generation"
unit-coverage-reviewed:
  - test/fast/molecules/lint_runner_test.rb
  - test/fast/organisms/lint_orchestrator_test.rb
tool-under-test: ace-lint
sandbox-layout:
  results/tc/01/: "help artifacts"
requires:
  tools: [ace-lint, standardrb, jq]
  ruby: ">= 3.0"
setup:
  - git-init
  - run: "cp $PROJECT_ROOT_PATH/mise.toml mise.toml && mise trust mise.toml"
  - copy-fixtures
  - agent-env:
      PROJECT_ROOT_PATH: "."
last-verified: 2026-02-24
verified-by: claude-opus-4
```

## Tags

The `tags` field enables discovery-time filtering with `--tags` and `--exclude-tags`.

**Naming conventions:**
- Cost tier is auto-included: `smoke`, `happy-path`, `deep`
- Use-case tags use the `use-case:{area}` pattern (e.g., `use-case:lint`, `use-case:config`)
- Custom tags are lowercase kebab-case

**Filtering semantics:**
- `--tags` uses OR: scenario matches if it has **any** of the specified tags
- `--exclude-tags` uses OR: scenario is excluded if it has **any** of the specified tags
- Both filters can be combined; exclude is applied after include

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
