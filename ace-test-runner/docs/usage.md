---
doc-type: user
title: Ace::TestRunner Usage Reference
purpose: Complete CLI reference for ace-test and ace-test-suite
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-test Usage Reference

`ace-test` executes package tests. `ace-test-suite` runs monorepo-wide suite definitions.

## `ace-test`

```bash
ace-test [PACKAGE] [TARGET] [options] [files...]
```

- `PACKAGE` (optional): package name (`ace-bundle`, `ace-search`) or path (`./ace-nav`, `/abs/path`).
- `TARGET` (optional): `atoms`, `molecules`, `organisms`, `models`, `fast`, `feat`, `all`, `quick`.
- `files` (optional): one or more `.rb` files or `file.rb:line` entries.

File args take precedence over target execution.

### Global and execution options

- `-f`, `--format FORMAT` (`progress`, `progress-file`, `json`)
- `--report-dir DIR`: root directory for saved reports
- `--save-reports`: persist full reports (default: true)
- `--fail-fast`: stop on first failure
- `--fix-deprecations`: patch deprecated test patterns when possible
- `--filter PATTERN`: run tests matching a name pattern
- `-g`, `--target TARGET`: force a target (`fast`, `feat`, `all`)
- `--color` / `--no-color`
- `-c`, `--config-path FILE`: explicit configuration file
- `--timeout SEC`: execution timeout in seconds
- `--max-display N`: max failures shown
- `--profile [N]`: show N slowest tests
- `--parallel`: run tests in parallel
- `--per-file`: execute each test file separately
- `--direct`: run in-process executor
- `--subprocess`: run in isolated subprocess mode
- `--ris`, `--run-in-sequence`: run targets in sequence
- `--risb`, `--run-in-single-batch`: run all tests in one batch
- `--set-default-rake`: set `ace-test` as default rake test command
- `--unset-default-rake`: remove rake integration
- `--check-rake-status`: inspect rake integration state

### Report cleanup and diagnostics

- `--cleanup-reports`: remove old report data
- `--cleanup-keep N`: keep latest N reports (default 10)
- `--cleanup-age DAYS`: remove reports older than days (default 30)
- `--quiet`, `-q`: suppress non-essential output
- `--verbose`, `-v`: include verbose output
- `--debug`, `-d`: print debug traces
- `--version`: print CLI version
- `--help`: print usage help

### Examples

```bash
ace-test
ace-test atoms
ace-test ace-bundle fast
ace-test ace-support-core feat
ace-test ace-support-core test/fast/atoms/some_test.rb
ace-test ace-support-core test/fast/atoms/some_test.rb:42
ace-test --format json --filter auth
ace-test --cleanup-reports
ace-test --set-default-rake
ace-test --check-rake-status
```

## `ace-test-suite`

```bash
ace-test-suite [options]
```

- `-c`, `--config FILE`: suite config path (default: `.ace/test/suite.yml`)
- `-p`, `--parallel N`: override max parallel worker count
- `-t`, `--timeout SEC`: fail any package subprocess that exceeds the timeout
- `-g`, `--group GROUP`: limit execution to a package group
- `--target TARGET`: pass an explicit package target to `ace-test` (for example `feat`)
- `-v`, `--verbose`: verbose output and backtraces
- `--progress`: live animated progress bars
- `--no-color`: disable colorized output
- `--help`: print usage help
- `--version`: print suite version

## Notes

- `ace-test` resolves package arguments using ACE package discovery.
- `ace-test-suite --timeout` is enforced at the suite layer and terminates the timed-out package process group before continuing with queued packages.
- Bare `ace-test <package>` resolves to the `fast` target.
- `feat` is the deterministic feature layer with controlled local IO.
- Scenario E2E is run with `ace-test-e2e <package>`, not `ace-test <package> e2e`.
- Explicit test files (`.rb` and `file.rb:line`) override target selection.
- Package defaults and user config are merged with CLI options.
