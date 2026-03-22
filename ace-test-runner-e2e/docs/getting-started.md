---
doc-type: user
title: Ace::Test::EndToEndRunner Getting Started
purpose: Tutorial for running your first E2E scenario with ace-test-runner-e2e
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-test-runner-e2e

## Prerequisites

- ACE repository available locally
- Ruby 3.2+
- `mise` installed so `mise exec --` can resolve ACE toolchain
- AI agent runtime/provider configured for `ace-test-e2e`

## Installation

`ace-test-runner-e2e` is part of this monorepo. From repo root:

```bash
mise exec -- ace-test-e2e --help
```

If the command resolves and prints help, your setup is ready.

## Running your first E2E test

Run a known scenario:

```bash
mise exec -- ace-test-e2e ace-lint TS-LINT-001
```

What happens:

- Scenario metadata is discovered from `ace-lint/test/e2e/TS-LINT-001-*/scenario.yml`.
- Setup runs in an isolated sandbox.
- Runner and verifier outputs are written to `.ace-local/test-e2e/...`.

## Understanding test formats

ACE documentation references two scenario conventions:

- **MT format**: single markdown scenario file (`MT-...`) used in legacy and migration contexts.
- **TS format**: directory-based scenario (`TS-...`) with `scenario.yml` and `TC-*` files.

`ace-test-e2e` executes TS scenarios directly. If you are maintaining older MT-style content, treat TS as the execution
target format.

## Creating a new test scenario

Use the package workflow to scaffold a scenario:

```bash
mise exec -- ace-bundle wfi://e2e/create
```

Then follow the workflow to create the `TS-*` directory, `scenario.yml`, and `TC-*` files in your package.

## Reading test reports

Each run writes reports under `.ace-local/test-e2e/` with timestamped folders.

```bash
ls .ace-local/test-e2e
```

Typical run output includes:

- scenario-level pass/fail summary
- per-test-case execution details
- verifier output and evidence links

## Common commands

| Command | Purpose |
|---------|---------|
| `mise exec -- ace-test-e2e ace-lint TS-LINT-001` | Run one specific TS scenario |
| `mise exec -- ace-test-e2e ace-lint` | Run all TS scenarios in one package |
| `mise exec -- ace-test-e2e ace-lint --tags smoke` | Run only matching-tag scenarios |
| `mise exec -- ace-test-e2e ace-lint TS-LINT-001 --dry-run` | Preview without execution |
| `mise exec -- ace-test-e2e-suite --affected` | Run suite for changed packages |
| `mise exec -- ace-test-e2e-suite --only-failures` | Re-run cached failures only |

## Next steps

- Use `mise exec -- ace-test-e2e --parallel N` for package-level parallelization.
- Use `mise exec -- ace-test-e2e-suite` for broader regression coverage.
- Use `mise exec -- ace-bundle wfi://e2e/setup-sandbox` to pre-provision complex sandboxes.
- Continue with [Usage Reference](usage.md) for full flags and options.
