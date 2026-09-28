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

### `ace-test-suite` examples

```bash
ace-test-suite --config .ace/test/suite.yml
ace-test-suite --config .ace/test/suite.yml --target fast
ace-test-suite --config .ace/test/suite.yml --timeout 1200
```

## Notes

- `ace-test` resolves package arguments using ACE package discovery.
- `ace-test-suite --timeout` is enforced at the suite layer and terminates the timed-out package process group before continuing with queued packages.
- Bare `ace-test <package>` resolves to the `fast` target.
- `feat` is the deterministic feature layer with controlled local IO.
- Scenario E2E is run with `ace-test-e2e <package>`, not `ace-test <package> e2e`.
- Canonical `ace-test-runner` scenario E2E invocation is `ace-test-e2e ace-test-runner`.
- For suite E2E coverage, prefer explicit config + target (`--config .ace/test/suite.yml`, optional `--target fast`) rather than fallback command branching.
- Explicit test files (`.rb` and `file.rb:line`) override target selection.
- Package defaults and user config are merged with CLI options.

## Hermetic Environment Contract

`ace-test` and `ace-test-suite` are deterministic by default. Every test child — serial, parallel, nested, in-process, and suite workers — is launched from a minimal documented environment instead of the invoking environment. Output labels the mode: `Test mode: deterministic (hermetic environment)`.

### Preserved keys

Only these parent keys survive into test children:

| Key | Purpose |
|-----|---------|
| `PATH` | Ruby/toolchain command lookup |
| `LANG`, `LC_ALL` | Locale |
| `TMPDIR`, `TMP`, `TEMP` | Temporary directories |

### Replaced keys

| Key | Replacement |
|-----|-------------|
| `HOME` | Test-owned fixture home under a temporary root |
| `XDG_CONFIG_HOME` | `<fixture home>/.config` |
| `XDG_CACHE_HOME` | `<fixture home>/.cache` |
| `XDG_DATA_HOME` | `<fixture home>/.local/share` |

The runner also sets `MT_NO_AUTORUN=1` for test children.

### Blocked configuration

All other parent environment is dropped, including ambient `LAB_*` sockets and selectors, `ACE_*` runtime/provider configuration, provider credentials (`ANTHROPIC_*`, `OPENAI_*`, `GEMINI_*`, `AWS_*`, and similar), Bundler/Gem project-selection variables, proxy variables, and language-injection variables (`RUBYOPT`, `RUBYLIB`, `PYTHONPATH`, ...). A live endpoint, provider, or Lab socket is never selected implicitly; a live Lab socket on the host cannot switch a deterministic run into live mode.

### Fixture overrides

Tests that need specific values supply them explicitly through runner configuration (project `.ace/test/runner.yml`):

```yaml
version: 1
environment:
  preserve:            # extra allowlisted keys beyond the table above
    - MY_TOOLCHAIN_KEY
  overrides:           # applied after sanitization; wins over preserved values
    MY_ENDPOINT: "http://127.0.0.1:1"
  require:             # must be non-empty after overrides, else setup error
    - MY_ENDPOINT
```

- `preserve` cannot un-block a blocked key; blocked ambient configuration is an error, never permission.
- `ace-test-suite` propagates its `test_suite.environment` overrides and requirements to every package worker; package-level runner configuration is more specific and wins for the same key.
- `require` failures are deterministic setup errors naming the missing key and the deterministic mode — values are never echoed.
- Credential-like override values are redacted in verbose diagnostics (fixture root and override key names only).

### Guarantees

- The invoking shell, the runner process environment, the real `HOME`, installed configuration, and service state are never mutated. In-process (`--direct`) execution applies the fixture environment for the duration of the run and restores the parent environment exactly afterwards.
- Fixture cleanup owns only the temporary root the runner created for the run.
- `ace-test-suite` gives each package its own fixture environment (parallel workers never share one) and launches `ace-test` co-located with the suite itself, so package runs use the matching runner version rather than an ambient PATH selection.
- Live integration stays opt-in through the E2E entrypoints (`ace-test-e2e`) with explicit target configuration.
