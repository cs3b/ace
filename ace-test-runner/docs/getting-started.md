---
doc-type: user
title: Ace::TestRunner Getting Started
purpose: Tutorial for running tests with ace-test-runner
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-test-runner

## Prerequisites

- Ruby 3.2+
- ACE monorepo available locally
- `bundle install` completed

## Installation

`ace-test-runner` is part of this monorepo. From repo root:

```bash
ace-test --help
```

If the command resolves and prints help, your setup is ready.

## Running your first tests

Run the default fast scope in the current package:

```bash
ace-test
```

Run only atom tests:

```bash
ace-test atoms
```

Run fast tests in `ace-test-runner` from repo root:

```bash
ace-test ace-test-runner fast
```

## Test Groups

| Group | Meaning |
| --- | --- |
| `atoms` | Low-level fast tests |
| `molecules` | Composed fast tests |
| `organisms` | Coordinating fast tests with stubbed boundaries |
| `models` | Data-structure behavior tests |
| `fast` | Default isolated package coverage |
| `feat` | Deterministic feature tests with controlled IO |
| `all` | `fast` then `feat` |
| `quick` | `atoms` + `molecules` |

## Cross-package execution

Target any package directly from the monorepo root:

```bash
ace-test ace-bundle quick
ace-test ace-search fast
ace-test ace-nav atoms
```

## Reading test reports

Run reports are stored in `.ace-local/test/reports` by default and linked by package.

```bash
ls .ace-local/test/reports
tree .ace-local/test/reports/test-runner
```

## Configuration basics

`ace-test` reads cascade config and command-line overrides in this order:

- `~/.ace/test/runner.yml`
- `.ace/test/runner.yml`
- `ace-test-runner/.ace-defaults/test-runner/config.yml`

Use an explicit path when needed:

```bash
ace-test --config-path /path/to/custom/config.yml
```

## Common commands

| Command | Purpose |
| --- | --- |
| `ace-test` | Run the default `fast` scope in current package |
| `ace-test atoms` | Run atom tests |
| `ace-test ace-bundle fast` | Run package + target |
| `ace-test ace-bundle feat` | Run package feature tests |
| `ace-test test/atoms/foo_test.rb` | Run a specific test file |
| `ace-test test/atoms/foo_test.rb:42` | Run test at file line |
| `ace-test --format json` | JSON output |
| `ace-test --filter my_pattern` | Filter by pattern |
| `ace-test --cleanup-reports` | Clean old reports |
| `ace-test-suite` | Run monorepo suite from `.ace/test/suite.yml` |

## Next steps

- Continue with [Usage Reference](usage.md) for full CLI flags.
- Review [Handbook Reference](handbook.md) for workflows and package guidance.
- Add failure analysis and tuning practices (profiling, targeted reruns, CI flags) in your local process.
