---
workflow-id: wfi-plan-e2e-changes
name: e2e/plan-changes
description: Analyze coverage matrix and produce a concrete E2E test change plan
version: "1.1"
source: ace-test-runner-e2e
---

# Plan E2E Changes Workflow

This workflow takes the review output (coverage matrix) from Stage 1 and produces a concrete change plan with classified actions for each existing and proposed TC.

**Pipeline position:** Stage 2 of 3 (Decide)

```text
ace-bundle wfi://e2e/review  →  ace-bundle wfi://e2e/plan-changes  →  ace-bundle wfi://e2e/rewrite
     (explore)                           ▶ (decide) ◀                           (execute)
```

## Arguments

- `PACKAGE` (required) - The package to plan changes for (e.g., `ace-lint`)
- `--review-report <path>` (optional) - Path to review report from Stage 1. If omitted, load `ace-bundle wfi://e2e/review` first.
- `--scope <scenario-id>` (optional) - Limit planning to a single scenario (e.g., `TS-LINT-001`)

## Workflow Steps

### 1. Load Review Output

**If `--review-report` provided:**
Read the file at the given path. Verify it contains a coverage matrix with the expected structure (features × unit tests × E2E columns).

**If no review report:**
Load `ace-bundle wfi://e2e/review` and capture the full output including coverage matrix, overlap analysis, gap analysis, and health status.

If `--scope` is provided, filter the review data to only the specified scenario and its related features.

### 2. Analyze Recent Changes

Determine what has changed in the package since each TC was last verified:

```bash
# Get last-verified dates from review output, then check changes since then
git log --oneline --since="{oldest-last-verified}" -- {PACKAGE}/lib/ {PACKAGE}/bin/
```

```bash
# Changed files relative to current state
git diff --name-only HEAD~20 -- {PACKAGE}/lib/ {PACKAGE}/bin/
```

Build a change inventory:
- **New features** — files/modules added since last verification
- **Modified features** — existing code with changes since last verification
- **Removed features** — deleted files or deprecated modules
- **Unchanged features** — stable code with no recent modifications

### 3. Classify Each Existing TC

For each TC listed in the coverage matrix, assign exactly one classification:

**REMOVE** — The TC should be deleted. Criteria (any one is sufficient):
- Full overlap with unit tests AND the TC does not test real binary/subprocess/filesystem
- The TC tests behavior that has been removed from the package
- The TC is a duplicate of another TC (same CLI invocation + same assertions)

For REMOVE due to overlap, replacement evidence is mandatory:
- Reference existing unit test file(s) and assertions that cover the removed behavior, OR
- Add a follow-up unit test action to the plan (file + behavior) before removal is considered complete.

**KEEP** — The TC has genuine E2E value and needs no changes. Criteria (all must be true):
- TC passes the E2E Value Gate (tests real CLI binary + external tools + filesystem I/O)
- Related source code has no changes since `last-verified`
- TC structure is valid and assertions are current

**MODIFY** — The TC has E2E value but needs updates. Criteria (any one is sufficient):
- Related source code changed since `last-verified` (assertions may be outdated)
- TC scope is too broad (should be narrowed to only E2E-exclusive aspects)
- TC scope is too narrow (missing assertions for related behavior in same CLI invocation)
- TC has structure issues flagged in the review

**CONSOLIDATE** — The TC should merge with another TC. Criteria (any one is sufficient):
- Multiple TCs share the same CLI invocation and could be a single TC with multiple assertions
- A scenario has more than 5 TCs (merge related TCs to reduce count)
- Separate TCs each check one assertion after the same setup

For each classification, document:
- The TC identifier
- The classification reason (specific, not generic)
- For REMOVE (overlap): replacement evidence (`existing unit tests` or `planned unit backfill`)
- For MODIFY: what specifically needs to change
- For CONSOLIDATE: the target TC and which assertions merge

### 4. Identify New TCs Needed

Review the coverage matrix for gaps that warrant new E2E tests:

**Candidates for new TCs:**
- Features with no E2E coverage that pass the E2E Value Gate
- New features from git changes (step 2) without any test coverage
- Error paths not covered by any existing TC

**For each proposed new TC, document:**
- Proposed title and objective
- What CLI command it exercises
- What it verifies that unit tests cannot
- Which scenario it belongs to (existing or new)

**Filter through Value Gate:**
For each candidate, answer: "Does this require the full CLI binary + real external tools + real filesystem I/O?"
- If NO: skip — unit tests cover this (or add explicit unit test action if coverage is missing)
- If YES: include in the plan

### 5. Propose Scenario Structure

Group all planned TCs (KEEP + MODIFY + CONSOLIDATE targets + ADD) into scenarios:

**Grouping rules:**
- 2-5 TCs per scenario (shared setup context)
- Group by CLI command or feature area
- Each scenario has a clear theme (e.g., "config validation", "report generation")

**For each scenario:**
- Name: `TS-{AREA}-{NNN}-{slug}`
- Tags: `[{cost-tier}, "use-case:{area}"]`
- List of TCs with ordering (errors first, happy path, structure verification, lifecycle)
- Shared setup requirements
- Fixtures needed

**Cost estimation:**
- Each TC ≈ 1 LLM invocation when run
- Estimate total scenarios × avg TCs × cost per invocation

### 6. Present Plan to User

Format the complete change plan:

```markdown
## E2E Change Plan: {package}

**Generated:** {timestamp}
**Based on:** {review-report path or "inline review"}
**Scope:** {package-wide or scenario-id}

### Impact Summary

| Metric | Current | Proposed | Change |
|--------|---------|----------|--------|
| Scenarios | {n} | {n} | {±n} |
| Test Cases | {n} | {n} | {±n} |
| Est. cost/run | ~${x} | ~${x} | {-n%} |

### REMOVE ({n} TCs)

| TC | Reason | Replacement Evidence |
|----|--------|----------------------|
| {tc-id} | Unit tests in {file} cover this fully | Existing: {test-file}:{test-name} |
| {tc-id} | Duplicate of {other-tc-id} | Existing: {test-file}:{test-name} |

### Unit Coverage Backfill ({n} actions)

| Action | File | Behavior |
|--------|------|----------|
| Add unit test | {test-file} | {behavior replacing removed E2E assertion} |

### KEEP ({n} TCs)

| TC | Notes |
|----|-------|
| {tc-id} | Genuine E2E value, no changes needed |

### MODIFY ({n} TCs)

| TC | Change Needed |
|----|---------------|
| {tc-id} | Update assertions — {feature} behavior changed in {commit} |
| {tc-id} | Narrow scope — remove assertions covered by unit tests |

### CONSOLIDATE ({n} TCs → {n} TCs)

| Source TCs | Target TC | Merged Assertions |
|------------|-----------|-------------------|
| {tc-a}, {tc-b} | {tc-a} | Combine {n} assertions into single TC |

### ADD ({n} new TCs)

| Proposed TC | Scenario | Verifies |
|-------------|----------|----------|
| {title} | {scenario-id} | {what it tests that units cannot} |

### Proposed Scenario Structure

```
TS-{AREA}-001-{slug}/  ({n} TCs)
  TC-001: {title}
  TC-002: {title}

TS-{AREA}-002-{slug}/  ({n} TCs)
  TC-001: {title}
  TC-002: {title}
  TC-003: {title}
```

### Next Steps

- Review and approve this plan
- Run `ace-bundle wfi://e2e/rewrite` to execute
- Or modify the plan and re-run
```

**If any classifications are uncertain**, flag them with a `?` and ask the user to confirm before proceeding.

## Example Invocations

**Plan changes with a prior review report:**
```bash
ace-bundle wfi://e2e/plan-changes
```

**Plan changes (runs review automatically):**
```bash
ace-bundle wfi://e2e/plan-changes
```

**Plan changes for a single scenario:**
```bash
ace-bundle wfi://e2e/plan-changes
```

## Error Handling

### No Review Data

If no `--review-report` is provided and `ace-bundle wfi://e2e/review` finds no tests:
```
No E2E tests found for {package}. Nothing to plan changes for.

To create the first E2E test: `ace-bundle wfi://e2e/create`
```

### Empty Coverage Matrix

If the review shows no features or tests:
```
Coverage matrix is empty for {package}. Ensure the package has both
implementation code and at least one E2E test before planning changes.
```

### User Rejection

If the user rejects the plan:
1. Ask which classifications they disagree with
2. Adjust the plan based on feedback
3. Re-present the updated plan
