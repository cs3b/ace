---
doc-type: bundle
purpose: Repository documentation for ACE testing taxonomy and execution patterns
ace-docs:
  last-updated: '2026-04-11'
---

# Testing Patterns

ACE uses three public test categories:

- `fast`
- `feat`
- `e2e`

These names describe isolation level first, not implementation detail.

## `fast`

Location:
- `test/fast/`

Purpose:
- default `ace-test` loop
- isolated checks for logic, parsing, state shaping, and in-process coordination

Rules:
- no real network
- no real subprocesses
- no real `git`, `tmux`, or shell command execution
- no filesystem-heavy environment setup
- use stubs, fakes, and inline data

Allowed:
- `capture_io`
- temp objects in memory
- deterministic local fixture reads when the test is still purely in-process

Common subfolders:
- `test/fast/atoms/`
- `test/fast/molecules/`
- `test/fast/organisms/`
- `test/fast/models/`
- `test/fast/commands/`

## `feat`

Location:
- `test/feat/`

Purpose:
- deterministic feature-slice coverage with controlled local IO
- verify a feature contract, CLI slice, or cross-component path without agent runtime

Rules:
- real local filesystem and tempdirs are allowed
- real subprocess execution is allowed when it stays local and deterministic
- config cascade and executable contract checks belong here
- external network and agent-runtime workflows do not belong here

Examples:
- CLI contract tests
- package copy/sandbox helper checks
- deterministic end-to-end behavior inside a controlled local environment

## `e2e`

Location:
- `test/e2e/TS-*/scenario.yml`

Purpose:
- real workflow validation through `ace-test-e2e`
- agent runtime, sandbox setup, and declared artifact verification

Rules:
- this is not part of `ace-test`
- this is the slowest layer
- use it for real user workflows and scenario validation, not for checks that fit in `fast` or `feat`

## Commands

Default fast loop:

```bash
ace-test <package>
```

Explicit deterministic feature coverage:

```bash
ace-test <package> feat
```

All deterministic package tests, in order:

```bash
ace-test <package> all
```

Scenario E2E:

```bash
ace-test-e2e <package>
```

## Group Ordering

`ace-test <package> all` runs:

1. `fast`
2. `feat`

It does not run `e2e`.

## Migration Note

During migration, some packages still expose compatibility aliases like `unit` or `integration`.
Those names are transitional. Public docs and new work should use only:

- `fast`
- `feat`
- `e2e`

## Related Guides

- `ace-nav guide://testing-philosophy`
- `ace-nav guide://test-organization`
- `ace-nav guide://testing`
