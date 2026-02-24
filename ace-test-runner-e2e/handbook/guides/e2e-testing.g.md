---
guide-id: g-e2e-testing
title: E2E Testing Guide
description: Conventions and best practices for agent-executed end-to-end tests
version: "2.0"
source: ace-test-runner-e2e
---

# E2E Testing Guide

## Overview

E2E tests are executed by an AI agent and reserved for behaviors that require real CLI execution, real tools, and real filesystem side effects.

## Canonical Conventions

- CLI split:
  - `ace-test-e2e` runs tests for a single package
  - `ace-test-e2e-suite` runs suite-level execution
- Scenario IDs follow `TS-<PACKAGE_SHORT>-<NNN>[-slug]`
- Test format is standalone pair only:
  - `TC-*.runner.md`
  - `TC-*.verify.md`
  - `runner.yml.md`
  - `verifier.yml.md`
- TC artifacts use `results/tc/{NN}/`
- Summary reports use `tcs-passed`, `tcs-failed`, `tcs-total`, and `failed[].tc`

## E2E Value Gate

Before adding a TC, confirm the behavior needs:
- full CLI binary execution
- real external tools/processes
- real filesystem I/O and environment state

If not, keep coverage in unit/integration tests.

## Cost and Scope

- Keep scenarios small and coherent.
- Typical scenario size: 2-5 TCs.
- Consolidate assertions that share the same command/setup into one TC.
- Use `cost-tier` to stage manual execution (`smoke` -> `standard` -> `deep`).

## Scenario Layout

```text
{package}/test/e2e/TS-{AREA}-{NNN}-{slug}/
  scenario.yml
  runner.yml.md
  verifier.yml.md
  TC-001-{slug}.runner.md
  TC-001-{slug}.verify.md
  fixtures/
```

## Required Scenario Evidence

In `scenario.yml`, record:
- `e2e-justification`
- `unit-coverage-reviewed`
- `cost-tier`

This prevents duplicate assertions across test layers.

## Authoring Rules

- Keep runner goals outcome-oriented and deterministic.
- Keep verifier expectations artifact-based.
- Preserve strict TC pairing (`runner` + `verify`).
- Keep outputs inside `results/tc/{NN}/`.
- Avoid hidden dependencies between TCs unless explicitly intended.

## Execution Artifacts

Reports are written under `.cache/ace-test-e2e/`:
- `{run-id}-{pkg}-{scenario}-reports/summary.r.md`
- `{run-id}-{pkg}-{scenario}-reports/experience.r.md`
- `{run-id}-{pkg}-{scenario}-reports/metadata.yml`

## Review Checklist

Before approving new/updated E2E tests:
- [ ] Scenario uses standalone pair format only
- [ ] `scenario.yml` omits legacy `mode` and `execution-model`
- [ ] `runner.yml.md` and `verifier.yml.md` exist
- [ ] Every TC has both `.runner.md` and `.verify.md`
- [ ] Artifacts are scoped to `results/tc/{NN}/`
- [ ] Value-gate metadata is present (`e2e-justification`, `unit-coverage-reviewed`, `cost-tier`)
