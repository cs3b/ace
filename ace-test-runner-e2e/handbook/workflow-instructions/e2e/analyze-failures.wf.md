---
doc-type: workflow
title: Analyze E2E Failures Workflow
purpose: analyze-e2e-failures workflow instruction
ace-docs:
  last-updated: 2026-04-08
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

Use these as mandatory corroborating evidence before classification:
- relevant scenario files:
  - `scenario.yml`
  - relevant `TC-*.runner.md`
  - relevant `TC-*.verify.md`
- relevant implementation path for the behavior under test
- at least one product-contract source:
  - unit or command tests, or
  - CLI help/docs, or
  - a clear implementation invariant

Do not classify from summary text alone when raw artifacts exist.
Do not classify a TC as `test-issue` until the implementation path has been inspected.
Treat `summary.r.md` as the canonical failed-TC source when suite-level prose disagrees.

## Analysis Procedure

1. Locate latest failing report directories
```bash
ls -lt .ace-local/test-e2e/*-reports/ 2>/dev/null | head -20
```

2. For each failing scenario, extract:
- failed TC IDs
- report ID and report directory
- canonical failed-TC source path
- reported category/evidence from metadata
- corroborating artifact evidence
- current scenario contract from runner/verifier files
- relevant implementation path for the claimed behavior
- at least one product-contract source establishing desired behavior

2a. Lock failure identity before classification
- Record the active failure tuple:
  - `report_id`
  - `report_dir`
  - `scenario`
  - `tc`
  - `canonical_evidence_source`
- Resolve the active TC in this order:
  1. `summary.r.md`
  2. raw `results/tc/{NN}/` artifacts
  3. `metadata.yml`
  4. suite final report prose only as narrative context
- If suite prose and scenario summary disagree, record `report-inconsistency` in the evidence notes and continue with the `summary.r.md` TC.

2b. Review the whole scenario before choosing a fix target
- Read every `TC-*.runner.md` and `TC-*.verify.md` in the failing scenario once.
- Note any shared contract drift that could affect multiple TCs:
  - artifact naming
  - required vs optional captures
  - reused setup assumptions
  - shared state-model expectations

3. Establish desired behavior before classification
- Name the desired behavior source for each failed TC
- State why that source is authoritative for the observed behavior
- If artifacts and implementation disagree, continue diagnostic reading before final classification

4. Reclassify each failed TC if needed
- Use `code-issue`, `test-issue`, or `runner-infrastructure-issue`
- `test-issue` is allowed only when implementation-backed analysis shows the product behavior is correct and the mismatch is in setup, runner capture, verifier logic, artifact naming, command contract drift, or stale expectation
- Before adding or preserving more artifacts, ask whether the failing artifact is actually part of the product behavior:
  - if it is only a runner-invented convenience file, classify the failure as `test-issue`
- Add confidence: `high|medium|low`
- Add one disconfirming check per TC that targets the strongest competing explanation
- If confidence is `medium` or `low`, run at least one additional diagnostic read/search before final decision

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

## Classification Gates

Before labeling a failure `test-issue`, confirm all of the following:
- the relevant implementation path was inspected
- the desired behavior source is explicit
- the mismatch is truly in artifact capture, naming, timing, selector choice, command shape, or stale expectation
- if output is transformed, normalized, or structured, the verifier is not incorrectly asserting a pre-transform literal string unless verbatim output is the product contract
- the active failure tuple is locked to the latest `summary.r.md`
- the scenario-wide runner/verifier review was completed and any shared drift was noted

Before labeling a failure `code-issue`, confirm all of the following:
- the failure is not already explained by stale runner/verifier/setup capture
- implementation or product-contract evidence contradicts the observed behavior

Examples:
- artifact drift:
  - verifier expects `cache.before/cache.after/cache.diff`
  - runner still emits `noreport.files`
  - classify `test-issue`
- stale command contract:
  - scenario uses `ace-task done`
  - current contract is `ace-task update <ref> --set status=done`
  - classify `test-issue`
- mixed evidence:
  - runner captures the wrong shifted step file
  - implementation also writes renumber metadata
  - inspect implementation before deciding whether the fix is runner-only or code+runner
- transformed output with brittle verifier:
  - verifier requires a raw README heading string
  - product emits normalized markdown-xml tokens and semantic content instead
  - classify `test-issue`
- synthetic artifact oracle:
  - runner requires a file whose filename is the token printed by the tool
  - stdout already contains the token and the product does not promise the file
  - classify `test-issue`

## Required Output Contract

Produce this section before exiting:

```markdown
## E2E Failure Analysis Report

| Report ID | Scenario / TC | Canonical TC Source | Category | Evidence | Desired Behavior Source | Implementation Evidence Path | Fix Target | Fix Target Layer | Primary Candidate Files | Fallback Candidate Files | Do-Not-Touch Boundaries | Confidence | Disconfirming Check | Rerun Scope |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 8r8e38c | TS-FOO-001 / TC-003 | .ace-local/test-e2e/.../summary.r.md | test-issue | summary + artifact mismatch details | current CLI help text + command test | ace-foo/lib/... | scenario files | test-scenario-runner | TC-003-foo.runner.md | TC-003-foo.verify.md | lib/** | high | replay the same command with corrected artifact capture | scenario |
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
- Failure identity lock: `report_id / scenario / tc / canonical_evidence_source`
- Scenario-wide drift notes: ...
```

## Success Criteria

- Every failed TC has a category and evidence
- Every failed TC has a locked failure identity tuple
- Every failed TC has an explicit desired behavior source
- Every failed TC has an implementation evidence path
- Category is traceable to report/artifact facts
- `test-issue` classifications are implementation-backed, not assumed
- Scenario-wide runner/verifier review was completed before fix targeting
- Fix target is explicit per failed TC
- Fix target files are explicit per failed TC (primary + fallback)
- No-touch boundaries are explicit per failed TC
- A single autonomous chosen fix decision is present per failed TC
- Rerun scope recommendation is cost-aware
- No code/scenario/runner edits were made in this workflow
