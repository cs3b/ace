---
doc-type: guide
title: E2E Testing Guide
purpose: Conventions and best practices for agent-executed end-to-end tests
ace-docs:
  last-updated: 2026-03-12
  last-checked: 2026-03-21
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
- Scenarios may declare `execution-tier` to control suite scheduling (`safe-parallel`, `low-parallel`, `serial`)

## Runner vs Verifier Contract

- Runner is **execution-only**:
  - perform user-like CLI actions in sandbox
  - produce evidence files under `results/tc/{NN}/`
  - do not issue PASS/FAIL verdicts
  - do not perform verifier-style assertion/classification
- Verifier is **verification-only**:
  - remain independent from the runner; do not reuse the same agent/session as the default verifier path
  - evaluate TC outcome from sandbox evidence
  - apply an **impact-first** evidence order:
    1. sandbox/project state impact
    2. explicit TC artifacts
    3. harness manifests and debug captures (`stdout`, `stderr`, `*.exit`, metadata) only as fallback
  - verify the output contract that the tool actually promises:
    - use semantic/structural checks for transformed or normalized output
    - use literal string checks only when verbatim preservation is part of the product contract
- Setup ownership:
  - sandbox preparation belongs to `scenario.yml` `setup:` + `fixtures/`
  - TC runner files must not define independent environment setup procedures

## Artifact Classes

Every required TC artifact must belong to exactly one of these classes:

- `command-capture`
  - raw command evidence such as `.stdout`, `.stderr`, `.exit`
- `state-oracle`
  - real side effects such as filesystem state, list output, status output, JSON snapshots, or product-owned output files
- `optional-support`
  - copied convenience files, grep extracts, summaries, notes, or other debug-only material

Rules:
- Required artifacts must be only `command-capture` or `state-oracle`.
- `optional-support` must never be the sole reason a semantically correct TC fails.
- Runner-invented synthetic artifacts are not valid primary oracles unless the tested behavior is specifically “create this file”.
- Keep the artifact gate strict by feeding it only deterministic behavior evidence.

## Harness Manifests

Every started TC should also have deterministic harness meta-artifacts under `results/tc/{NN}/`:

- `tc.start.json`
- `commands.ndjson`
- `artifacts.json`
- `tc.final.json`

These are not primary behavior oracles. They exist to distinguish:
- command never started
- command ran but evidence was incomplete
- verifier reached a real behavior judgment

Use them to strengthen diagnosis, not to replace `command-capture` or `state-oracle`.

## E2E Value Gate

Before adding a TC, confirm the behavior needs:
- full CLI binary execution
- real external tools/processes
- real filesystem I/O and environment state

If not, keep coverage in unit/integration tests.

Prefer `minitest` instead of E2E when the behavior is mainly:
- parsing
- formatter normalization
- fallback naming logic
- config/default resolution
- helper-file materialization that is not itself product behavior

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
6. **Artifact gate** — required runner artifacts are checked before verifier execution; missing artifacts fail as infrastructure issues
7. **Report** — `PipelineReportGenerator` produces deterministic summary from verifier output

API providers use a single-prompt approach (runner and verifier in one pass).

The verifier is always-on for standalone goal-mode TCs in the CLI pipeline. For procedural runs guided by `ace-bundle wfi://e2e/run`, the verifier is opt-in via `--verify`.

## Scenario Classes

Use the verification model that matches the scenario boundary:

- `local-deterministic`
  - no live provider dependency
  - must always produce the full required evidence set
- `stateful-deterministic`
  - persistent git/filesystem/task state
  - must include preflight state proof plus post-state oracle
- `provider-live`
  - external provider/final synthesis may fail legitimately
  - verify chain completion and recorded final-stage outcome
  - do not require all success-path copied artifacts as mandatory evidence

## Scenario Layout

```text
{package}/test-e2e/scenarios/TS-{AREA}-{NNN}-{slug}/
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
- Keep required artifact sets small. Prefer fewer stable captures over many convenience files.
- Do not anchor verifier expectations to raw source strings when the tool emits transformed output.
- Prefer path inclusion, semantic content, and structural markers over exact source headings or incidental wording.
- If the product intentionally preserves verbatim output, say that explicitly in the verifier contract.
- Declare concrete runner artifacts; if a runner-owned artifact is optional in practice, remove it from the contract instead of leaving it implicit.
- Do not make up side quests for the runner:
  - no token-named files
  - no copied outputs just to satisfy the verifier
  - no notes file as the only pass/fail oracle unless the product itself is generating a note/report
- Preserve strict TC pairing (`runner` + `verify`).
- Keep outputs inside `results/tc/{NN}/`.
- Avoid hidden dependencies between TCs unless explicitly intended.
- When fixing a red scenario, use `summary.r.md` as the canonical failed-TC source and review the entire scenario contract before editing any single TC.
- A scenario-wide review does not mean every TC must be edited; it means shared runner/verifier drift must be checked before a TC-local fix is declared complete.

Example:
- Bad: require `README.md ("Test Application")` when the formatter normalizes markdown into structured tokens.
- Good: require `README.md` inclusion plus semantic README content or formatter-emitted structural markers actually produced by the tool.

## Runner Pattern

Keep runner files short and explicit:

- one short goal
- one explicit `Capture:` block
- one short `Constraints:` block
- behavior-focused steps only

Good runner behavior:
- run the real CLI flow
- capture the command result
- capture one or two real state oracles when needed

Bad runner behavior:
- invent support artifacts as primary proof
- create custom filenames derived from command output only for verifier convenience
- capture many overlapping files “just in case”

## Verifier Pattern

Verifier judgment should be semantic but bounded.

Evidence order:
1. `state-oracle`
2. `command-capture`
3. `optional-support`

Verifier responsibilities:
- report what behavior was confirmed working
- report what behavior was contradicted or not confirmed
- fail only when:
  - behavior is contradicted, or
  - required `command-capture` / `state-oracle` evidence is missing

Failure reporting should distinguish:
- `behavior-status`: `pass | fail | not_reached`
- `evidence-status`: `complete | incomplete | invalid-contract`
- `failure-class`: `behavior-fail | artifact-incomplete | invalid-contract | setup-error`

Verifier prohibitions:
- do not fail solely because an `optional-support` artifact is absent
- do not require runner-invented synthetic artifacts when stdout/state already proves the behavior
- do not use exact string checks when semantic or structural checks are the real product contract
- do not use same-session runner memory as the primary oracle when sandbox evidence disagrees

## Examples

### `ace-b36ts`

- Bad:
  - run `ace-b36ts`, then create a token-named file and verify the filename
- Good:
  - capture `encode-today.stdout`, `.stderr`, `.exit`
  - verify the token format from stdout

### Transformed output

- Bad:
  - require a raw source heading after the formatter normalizes the content
- Good:
  - verify semantic content, inclusion, and structure actually emitted by the formatter

### Stateful lifecycle

- Bad:
  - require an extra notes file after `remove`
- Good:
  - verify exit status, list output, and real filesystem state

## Execution Artifacts

Reports are written under `.ace-local/test-e2e/`:
- `{run-id}-{pkg}-{scenario}-reports/summary.r.md`
- `{run-id}-{pkg}-{scenario}-reports/experience.r.md`
- `{run-id}-{pkg}-{scenario}-reports/metadata.yml`
- `{run-id}-final-report.md` suite report prose is narrative only; canonical failed-TC identity comes from the scenario report directory, especially `summary.r.md`

## Review Checklist

Before approving new/updated E2E tests:
- [ ] Scenario uses standalone pair format only
- [ ] `scenario.yml` omits legacy `mode` and `execution-model`
- [ ] `runner.yml.md` and `verifier.yml.md` exist
- [ ] Every TC has both `.runner.md` and `.verify.md`
- [ ] Artifacts are scoped to `results/tc/{NN}/`
- [ ] Value-gate metadata is present (`e2e-justification`, `unit-coverage-reviewed`, `cost-tier`)
