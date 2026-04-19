---
name: e2e-analyze-failures
description: Analyze failing E2E scenarios, classify root causes, and surface docs/help drift before fixes.
allowed-tools:
- Bash(ace-bundle:*)
- Read
- Grep
- Glob
doc-type: workflow
title: Analyze E2E Failures Workflow
purpose: analyze-e2e-failures workflow instruction
ace-docs:
  last-updated: 2026-04-19
  last-checked: 2026-04-19
---

# Analyze E2E Failures Workflow

## Goal

Analyze failing E2E scenarios and classify each failed test case before any fix is applied.

This workflow determines whether each failure is caused by:
- application/tool code
- E2E test definition/spec
- E2E runner/infrastructure
- stale, missing, or misleading docs/help that made the public user path unclear

## Hard Rule

- Do not edit package code, scenario files, or runner code in this workflow.
- Do not run rewrite/fix actions here.
- This workflow ends with an analysis report only.
- Do not ask the user where/how to fix during this workflow; decide from evidence.

## Prerequisites

- E2E tests have already run and produced cache artifacts
- Reports are available under `.ace-local/test-e2e/*-reports/`

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`
- Read E2E guide: `ace-bundle guide://e2e-testing`
- Check recent changes: `git log --oneline -10`

## Classification Categories

Use exactly one category per failed TC:

1. `code-issue`
- Tool behavior is incorrect relative to expected product behavior

2. `test-issue`
- Scenario/TC expectation, fixture, or steps are stale/incorrect

3. `runner-infrastructure-issue`
- Sandbox/setup/provider/parsing/orchestration issue

Public-surface interpretation rules:
- If the TC fails because it encoded a hidden recipe or workaround, classify it as `test-issue`.
- If the intended user job is valid but the public CLI/docs/`--help` do not support it cleanly, classify it as `code-issue` with a fix target in product docs/help or CLI help rather than preserving the workaround.
- If the failure is about internal detail that a user cannot or need not observe from the public surface, prefer narrowing/removing the TC over deepening the runner.

## Required Evidence Sources

Use these files as primary evidence:
- `summary.r.md`
- `experience.r.md`
- `metadata.yml`
- Relevant artifacts in `results/tc/{NN}/`

Aggregate suite/package reports are indexing aids only. For failed TC IDs, categories, and evidence, the per-scenario `report.md` in the referenced report directory is the canonical source of truth.

## Analysis Procedure

1. Locate latest failing report directories
```bash
ls -lt .ace-local/test-e2e/*-reports/ 2>/dev/null | head -20
```

2. For each failing scenario, extract:
- failed TC IDs
- reported category/evidence from metadata
- corroborating artifact evidence
- if analyzing from a suite/package report, read the referenced per-scenario `report.md` before accepting any failed-TC mapping

If the aggregate report and per-scenario report disagree:
- trust the per-scenario `report.md`
- classify the mismatch itself as a runner/reporting issue in your analysis notes
- do not plan fixes from the aggregate failed-TC mapping alone

3. Reclassify each failed TC if needed
- Use `code-issue`, `test-issue`, or `runner-infrastructure-issue`
- Add confidence: `high|medium|low`
- Add one disconfirming check per TC
- If confidence is `medium` or `low`, run at least one additional diagnostic read/search before final decision
- Before claiming sandbox escape or fixture contamination, compare repo `git status --short` before and after the relevant E2E run when that evidence is available. Do not infer escape solely from an after-the-fact dirty tree.
- Check whether the scenario required a hidden recipe or workaround to reach the goal. If yes, record that explicitly in the evidence and classification.

4. Audit docs/help drift for each failed TC
- Identify the user job the TC is trying to prove.
- Check the public surface that a normal user or agent would consult:
  - package `README.md`
  - package `docs/usage.md`
  - package `docs/getting-started.md`
  - package `docs/handbook.md`
  - direct command `--help` output for the command involved
- Record whether the failure exposes stale, missing, or misleading docs/help.
- If drift exists, list concrete docs/help update targets and make them part of the fix target.
- If no drift exists, record `None` explicitly. Do not omit the docs/help assessment.

5. Recommend rerun scope (cost-aware)
- `scenario` (default)
- `package`
- `suite`
with explicit rationale

6. Choose autonomous fix decision per failed TC
- Select a single primary fix action
- Provide concrete file targets in priority order
- Define explicit no-touch boundaries
- Do not emit option lists that require user selection

## Required Output Contract

Produce this section before exiting:

```markdown
## E2E Failure Analysis Report

| Scenario / TC | Category | Evidence | Fix Target | Fix Target Layer | Primary Candidate Files | Fallback Candidate Files | Do-Not-Touch Boundaries | Confidence | Disconfirming Check | Rerun Scope |
|---|---|---|---|---|---|---|---|---|---|---|
| TS-FOO-001 / TC-003 | test-issue | summary + artifact mismatch details | scenario files | test-scenario-runner | TC-003-foo.runner.md | TC-003-foo.verify.md | lib/** | high | re-run scenario after spec adjustment | scenario |
```

Then produce a docs/help drift section. This section is required even when no drift is found:

```markdown
## Docs / Help Drift From E2E Failures

| Scenario / TC | User Job | Public Surface Checked | Drift Found | Evidence | Update Targets | Action |
|---|---|---|---|---|---|---|
| TS-FOO-001 / TC-003 | user-facing job being tested | README, docs/usage.md, --help | yes | docs show stale flag missing from help | docs/usage.md, CLI --help | update docs/help before preserving scenario path |
| TS-BAR-001 / TC-001 | user-facing job being tested | README, docs/usage.md, --help | no | public path is documented and help matches | None | no docs/help update |
```

Then include:

```markdown
## Fix Decisions
- First item to fix: ...
- Chosen fix decision: ...
- Why this target first (unblocks most): ...

### Execution Plan Input
- First item to fix: ...
- Why first (unblocks most): ...
- Required verification commands: ...
- Expected pass criteria per command: ...
```

## Success Criteria

- Every failed TC has a category and evidence
- Category is traceable to report/artifact facts
- Fix target is explicit per failed TC
- Fix target files are explicit per failed TC (primary + fallback)
- No-touch boundaries are explicit per failed TC
- Docs/help drift is assessed for every failed TC with concrete update targets or `None`
- A single autonomous chosen fix decision is present per failed TC
- Rerun scope recommendation is cost-aware
- No code/scenario/runner edits were made in this workflow
