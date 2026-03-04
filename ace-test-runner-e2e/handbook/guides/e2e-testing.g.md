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
- Scenarios declare `tags` for discovery-time filtering via `--tags`/`--exclude-tags`

## Runner vs Verifier Contract

- Runner is **execution-only**:
  - perform user-like CLI actions in sandbox
  - produce evidence files under `results/tc/{NN}/`
  - do not issue PASS/FAIL verdicts
  - do not perform verifier-style assertion/classification
- Verifier is **verification-only**:
  - evaluate TC outcome from sandbox evidence
  - apply an **impact-first** evidence order:
    1. sandbox/project state impact
    2. explicit TC artifacts
    3. debug captures (`stdout`, `stderr`, `*.exit`, metadata) only as fallback
- Setup ownership:
  - sandbox preparation belongs to `scenario.yml` `setup:` + `fixtures/`
  - TC runner files must not define independent environment setup procedures

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
- Use `cost-tier` to stage execution (`smoke` → `happy-path` → `deep`).

## Execution Pipeline

CLI providers (`ace-test-e2e`, `ace-test-e2e-suite`) use a deterministic 6-phase pipeline:

1. **Setup** — `SetupExecutor` creates sandbox (git init, mise.toml, .ace symlinks, results/tc/{NN}/ dirs)
2. **Runner prompt** — `SkillPromptBuilder` assembles context from `runner.yml.md` and `TC-*.runner.md`
3. **Runner LLM** — Agent executes TC steps in sandbox, produces artifacts
4. **Verifier prompt** — `SkillPromptBuilder` assembles context from `verifier.yml.md` and `TC-*.verify.md`
5. **Verifier LLM** — Independent agent evaluates artifacts against expectations
6. **Report** — `PipelineReportGenerator` produces deterministic summary from verifier output

API providers use a single-prompt approach (runner and verifier in one pass).

The verifier is always-on for standalone goal-mode TCs in the CLI pipeline. For procedural runs via `/ace-e2e-run`, the verifier is opt-in via `--verify`.

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
- `tags` (cost-tier tag + use-case tags)
- `e2e-justification`
- `unit-coverage-reviewed`
- `cost-tier`

This prevents duplicate assertions across test layers.

## Authoring Rules

- Keep runner goals outcome-oriented and deterministic.
- Keep verifier expectations impact-first, then artifacts, then debug fallback.
- Preserve strict TC pairing (`runner` + `verify`).
- Keep outputs inside `results/tc/{NN}/`.
- Avoid hidden dependencies between TCs unless explicitly intended.

## Execution Artifacts

Reports are written under `.ace-local/test-e2e/`:
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
