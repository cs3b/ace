---
doc-type: workflow
title: Analyze E2E Failures Workflow
purpose: analyze-e2e-failures workflow instruction
ace-docs:
  last-updated: 2026-03-04
  last-checked: 2026-03-21
---

# Analyze E2E Failures Workflow

## Goal

Analyze failing E2E scenarios and classify each failed test case before any fix is applied.

This workflow determines whether each failure is caused by:
- application/tool code
- E2E test definition/spec
- E2E runner/infrastructure

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

## Required Evidence Sources

Use these files as primary evidence:
- `summary.r.md`
- `experience.r.md`
- `metadata.yml`
- Relevant artifacts in `results/tc/{NN}/`

## Analysis Procedure

1. Locate latest failing report directories
```bash
ls -lt .ace-local/test-e2e/*-reports/ 2>/dev/null | head -20
```

2. For each failing scenario, extract:
- failed TC IDs
- reported category/evidence from metadata
- corroborating artifact evidence

3. Reclassify each failed TC if needed
- Use `code-issue`, `test-issue`, or `runner-infrastructure-issue`
- Add confidence: `high|medium|low`
- Add one disconfirming check per TC
- If confidence is `medium` or `low`, run at least one additional diagnostic read/search before final decision

4. Recommend rerun scope (cost-aware)
- `scenario` (default)
- `package`
- `suite`
with explicit rationale

5. Choose autonomous fix decision per failed TC
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
- A single autonomous chosen fix decision is present per failed TC
- Rerun scope recommendation is cost-aware
- No code/scenario/runner edits were made in this workflow