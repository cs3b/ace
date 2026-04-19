---
doc-type: guide
title: E2E Testing Guide
purpose: Conventions and best practices for agent-executed end-to-end tests
ace-docs:
  last-updated: 2026-04-19
  last-checked: 2026-04-19
---

# E2E Testing Guide

## Overview

E2E tests are executed by an AI agent and reserved for behaviors that require real CLI execution, real tools, and real filesystem side effects.
They must also answer a user-journey question: can a user do the job from the tool's public surface, and how much friction does that journey have?

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
- TC outcome artifacts use `results/tc/{NN}/`
- Summary reports use `tcs-passed`, `tcs-failed`, `tcs-total`, and `failed[].tc`
- Scenarios declare `tags` for discovery-time filtering via `--tags`/`--exclude-tags`

## Runner vs Verifier Contract

- Runner is **execution-only**:
  - perform user-like CLI actions in sandbox
  - produce only final outcome evidence under `results/tc/{NN}/`
  - return final runner observations through the harness contract
  - do not issue PASS/FAIL verdicts
  - do not perform verifier-style assertion/classification
  - do not invent workarounds or hidden command recipes to compensate for docs/help/CLI gaps
- Verifier is **verification-only**:
  - evaluate TC outcome from sandbox evidence
  - use runner observations as the only non-filesystem secondary evidence source
  - apply an **impact-first** evidence order:
    1. sandbox/project state impact
    2. runner observations
    3. explicit TC artifacts that are true product outcomes
    4. debug captures (`stdout`, `stderr`, `*.exit`, metadata) only as fallback
- Setup ownership:
  - sandbox preparation belongs to `scenario.yml` `setup:` + `fixtures/`
  - TC runner files must not define independent environment setup procedures

## E2E Value Gate

Before adding a TC, confirm the behavior needs:
- full CLI binary execution
- real external tools/processes
- real filesystem I/O and environment state

If not, keep coverage in `fast`/`feat` tests.

## Public-Surface Gate

Before keeping or adding a goal-style TC, confirm the user job is achievable from:
- package README / usage docs
- `--help`
- declared fixtures/setup
- the tool under test itself

Reject or rewrite the TC if it depends on:
- hidden recipes embedded in runner instructions
- workaround branches for unsupported or undocumented behavior
- direct supporting-tool probes as the primary oracle
- internal details that are not necessary to prove the user job

When an E2E failure shows that a valid user job is not discoverable from docs, usage guides, or `--help`, treat that as
docs/help drift. Failure analysis must record the stale or missing public surface and the exact docs/help target to
update instead of teaching the runner a workaround.

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

The verifier is always-on for standalone goal-mode TCs in the CLI pipeline. For procedural runs guided by `ace-bundle wfi://e2e/run`, the verifier is opt-in via `--verify`.

## Scenario Layout

```text
{package}/test/feat/**/*_test.rb
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
- Keep runner goals aligned with the public user path; if the runner needs a workaround, surface that as friction rather than teaching the workaround.
- Keep verifier expectations impact-first, then artifacts, then debug fallback.
- Preserve strict TC pairing (`runner` + `verify`).
- Keep `results/tc/{NN}/` for outcome artifacts only.
- Do not instruct runners to create helper YAML, path files, command files, or reflections in `results/`.
- Do not judge success from runner-authored summaries when final sandbox state can prove the goal directly.
- Use runner observations only to explain ambiguity or missing side effects, not to replace missing end-state evidence.
- Treat any workaround noted in runner observations as a product/docs/help or scenario-design smell that must be fixed, not preserved.
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
- [ ] Verifier primary oracle is final sandbox state or real product output, not helper artifacts
- [ ] Runner observations are the only non-filesystem secondary evidence source
- [ ] Scenario can be completed from docs/usage/`--help` without hidden recipes or workaround instructions
- [ ] Any friction/workaround found during review is treated as a gap, not as a runner script opportunity
- [ ] Failure analysis records docs/help drift from failed public user paths, or explicitly records `None`
- [ ] Value-gate metadata is present (`e2e-justification`, `unit-coverage-reviewed`, `cost-tier`)
