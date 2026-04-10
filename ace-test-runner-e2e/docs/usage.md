---
doc-type: user
title: Ace::Test::EndToEndRunner Usage Reference
purpose: Complete CLI reference for ace-test-e2e and ace-test-e2e-suite
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-test-runner-e2e Usage Reference

`ace-test-e2e` runs E2E scenarios for one package. `ace-test-e2e-suite` runs across packages.

## `ace-test-e2e`

```bash
ace-test-e2e PACKAGE [TEST_ID] [OPTIONS]
```

- `PACKAGE` (required): package name such as `ace-lint`
- `TEST_ID` (optional): specific scenario ID such as `TS-LINT-001`

### Options

- `--provider=VALUE`: provider:model (default: `claude:haiku@yolo`)
- `--cli-args=VALUE`: extra provider CLI args
- `--timeout=VALUE`: timeout per test in seconds (default: `600`)
- `--parallel=VALUE`: scenarios in parallel (`1` = sequential, default: `8`)
- `--progress` / `--no-progress`: animated progress display
- `--run-id=VALUE`: fixed run ID for deterministic report paths
- `--report-dir=VALUE`: explicit report directory path
- `--dry-run` / `--no-dry-run`: preview scenarios without execution
- `--tags=VALUE`: comma-separated tags to include
- `--verify` / `--no-verify`: run independent verifier pass
- `--quiet`, `-q`: suppress non-essential output
- `--verbose`, `-v`: verbose output
- `--debug`, `-d`: debug output
- `--help`, `-h`: show help

### Output and exits

- Exit code `0`: all selected scenarios passed
- Exit code `1`: one or more scenarios failed or errored
- Default report path: `.ace-local/test-e2e/{timestamp}-{pkg}-{id}-reports/`

### Examples

```bash
ace-test-e2e ace-lint TS-LINT-001
ace-test-e2e ace-lint
ace-test-e2e ace-lint --provider gemini:flash
ace-test-e2e ace-lint --provider glite
ace-test-e2e ace-lint --tags smoke
ace-test-e2e ace-lint TS-LINT-003 --dry-run
```

## `ace-test-e2e-suite`

```bash
ace-test-e2e-suite [PACKAGES] [OPTIONS]
```

- `PACKAGES` (optional): comma-separated package list, for example `ace-bundle,ace-lint`

### Options

- `--parallel=VALUE`: suite worker count (`0` = sequential, default: `8`)
- `--affected` / `--no-affected`: test only changed/affected packages
- `--only-failures` / `--no-only-failures`: rerun only previously failed scenarios
- `--cli-args=VALUE`: extra provider CLI args
- `--provider=VALUE`: provider:model (default: `claude:haiku@yolo`)
- `--timeout=VALUE`: timeout per scenario in seconds (default: `600`)
- `--tags=VALUE`: comma-separated tags to include
- `--exclude-tags=VALUE`: comma-separated tags to exclude
- `--progress` / `--no-progress`: animated progress display
- `--verify` / `--no-verify`: run independent verifier pass per scenario
- `--quiet`, `-q`: suppress non-essential output
- `--verbose`, `-v`: verbose output
- `--debug`, `-d`: debug output
- `--help`, `-h`: show help

### Output and exits

- Exit code `0`: all scenarios passed
- Exit code `1`: one or more scenarios failed or errored

### Examples

```bash
ace-test-e2e-suite
ace-test-e2e-suite ace-bundle,ace-lint
ace-test-e2e-suite --parallel 4
ace-test-e2e-suite --affected
ace-test-e2e-suite --affected --parallel 8
ace-test-e2e-suite --only-failures
ace-test-e2e-suite --affected --only-failures
ace-test-e2e-suite --tags smoke,happy-path
ace-test-e2e-suite --exclude-tags deep
ace-test-e2e-suite --cli-args dangerously-skip-permissions
```

## `ace-test-e2e-sh`

```bash
ace-test-e2e-sh <test-dir> [command...]
```

Opens a shell or runs a command inside an E2E sandbox directory. Useful for inspecting sandbox state, running ad-hoc commands against test fixtures, or debugging failed scenarios.

- `test-dir` (required): sandbox directory path (must be under `.ace-local/test-e2e/`)
- `command` (optional): command to execute; omit for an interactive bash session

The tool validates that the path is inside `.ace-local/test-e2e/` and sets `PROJECT_ROOT_PATH` to the sandbox directory.

### Examples

```bash
ace-test-e2e-sh .ace-local/test-e2e/i50jj3-lint-001-reports bash
ace-test-e2e-sh .ace-local/test-e2e/i50jj3-lint-001-reports git status
ace-test-e2e-sh .ace-local/test-e2e/i50jj3-lint-001-reports ls results/
```

## Notes

- `ace-test-e2e` is scenario-only and discovers package-local TS scenarios from `test-e2e/scenarios/`.
- Scenario metadata is read from each scenario directory's `scenario.yml`.
- Use `--dry-run` before long executions when validating selection and tags.
- Use `--only-failures` in suite mode to shorten rerun loops after large failures.
