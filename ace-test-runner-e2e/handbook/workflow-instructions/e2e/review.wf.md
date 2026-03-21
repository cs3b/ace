---
doc-type: workflow
title: Review E2E Tests Workflow
purpose: Deep exploration producing a coverage matrix of functionality, unit tests, and E2E tests
ace-docs:
  last-updated: 2026-03-12
  last-checked: 2026-03-21
---

# Review E2E Tests Workflow

This workflow performs deep exploration of a package to produce a **coverage matrix** mapping functionality to unit test and E2E test coverage. The matrix is the primary input for Stage 2 (planning changes).

During review, treat the runner/verifier split as a first-class quality check:
- Runner must be execution-only (no verdict language).
- Verifier must be impact-first (sandbox impact before artifacts/debug).

**Pipeline position:** Stage 1 of 3 (Explore)

```text
ace-bundle wfi://e2e/review  →  ace-bundle wfi://e2e/plan-changes  →  ace-bundle wfi://e2e/rewrite
   ▶ (explore) ◀                           (decide)                             (execute)
```

## Arguments

- `PACKAGE` (required) - The package to review (e.g., `ace-lint`)
- `--scope <scenario-id>` (optional) - Limit review to a single scenario and its related features (e.g., `TS-LINT-001`)

## Workflow Steps

### 1. Identify Scope

Validate the package exists and determine review scope:

```bash
test -d "{PACKAGE}" && echo "Package exists" || echo "Package not found"
```

If package not found, list available packages:
```bash
ls -d */ | grep -E "^ace-" | sed 's/\/$//'
```

**Scope determination:**
- If `--scope <scenario-id>` provided: focus on that scenario and the features it tests
- Otherwise: full package review

### 2. Inventory Package Functionality

Map all user-facing features of the package:

**List CLI commands:**
```bash
ls {PACKAGE}/bin/ 2>/dev/null
```

**List command implementations:**
```bash
find {PACKAGE}/lib -path "*/commands/*.rb" -o -path "*/commands.rb" 2>/dev/null | sort
```

**For each command, identify key features:**
- Read the command file to find subcommands, flags, and modes
- List distinct behaviors (e.g., "lint with autofix", "lint dry-run", "lint specific file")
- Note external tool dependencies (e.g., StandardRB, Rubocop)

**Get unit test baseline:**
```bash
cd {PACKAGE} && ace-test --dry-run 2>/dev/null || echo "No dry-run available"
```

```bash
find {PACKAGE}/test -name "*_test.rb" 2>/dev/null | wc -l
```

Build a feature inventory:

| Feature | Command | External Tools | Description |
|---------|---------|----------------|-------------|
| {name} | {CLI command} | {tools or "none"} | {what it does} |

### 3. Inventory Unit Test Coverage

Map what unit tests cover at each layer:

**List all test files by layer:**
```bash
find {PACKAGE}/test/atoms -name "*_test.rb" 2>/dev/null | sort
find {PACKAGE}/test/molecules -name "*_test.rb" 2>/dev/null | sort
find {PACKAGE}/test/organisms -name "*_test.rb" 2>/dev/null | sort
```

**For each test file:**
- Read the file to extract test method names (`def test_*` or `it "..."` blocks)
- Count assertions (`assert_*` calls)
- Identify which feature/behavior each test covers

Build a unit test map:

| Test File | Layer | Feature Covered | Test Count | Assertion Count |
|-----------|-------|-----------------|------------|-----------------|
| {path} | atom | {feature} | {n} | {n} |

### 4. Inventory Existing E2E Coverage

Discover all E2E tests for the package:

```bash
find {PACKAGE}/test/e2e -name "scenario.yml" -path "*/TS-*" 2>/dev/null | sort
```

**For each scenario/TC:**
- Read the file and extract frontmatter metadata:
  - `test-id`, `title`, `area`, `priority`
  - `tags`, `cost-tier`, `e2e-justification`, `unit-coverage-reviewed`
  - `last-verified`, `verified-by`
- Extract the objective (what the TC verifies)
- Identify which CLI commands the TC runs
- Count verification steps (PASS/FAIL checks)
- Map to the feature it tests
- Mark TC evidence status:
  - `complete` when `e2e-justification` is present and `unit-coverage-reviewed` has at least one path
  - `missing` otherwise

If `--scope` was provided, filter to only the specified scenario.

Build an E2E test map:

| TC ID | Title | CLI Command | Feature Tested | Verifications | Tags | Cost Tier | E2E Justification | Unit Coverage Reviewed | Evidence |
|-------|-------|-------------|----------------|---------------|------|-----------|-------------------|------------------------|----------|
| {id} | {title} | {command} | {feature} | {n} | {tags} | {tier} | {reason or "(missing)"} | {files or "(missing)"} | {complete/missing} |

### 5. Build Coverage Matrix

Combine the three inventories into a single coverage matrix:

**Matrix structure:**
- **Rows:** Features/behaviors from step 2
- **Columns:** Unit Tests (atoms/molecules/organisms) | E2E Tests
- **Cells:** Test file references + counts, or "none"

```markdown
### Coverage Matrix

| Feature | Unit Tests | E2E Tests | Status |
|---------|-----------|-----------|--------|
| {feature} | {test files} ({n} assertions) | {TC IDs} ({n} verifications) | Covered |
| {feature} | {test files} ({n} assertions) | none | Unit-only |
| {feature} | none | {TC IDs} ({n} verifications) | E2E-only |
| {feature} | {test files} ({n} assertions) | {TC IDs} ({n} verifications) | Overlap |
| {feature} | none | none | Gap |
```

**Classify each row:**
- **Covered** — Both unit and E2E tests exist, and they test different aspects (unit tests logic, E2E tests CLI pipeline)
- **Unit-only** — Unit tests cover this but no E2E test exists. May or may not need E2E depending on Value Gate.
- **E2E-only** — E2E test exists but no unit test. Valid if the behavior is inherently E2E (subprocess execution, filesystem discovery).
- **Overlap** — Both unit and E2E test the same assertions. E2E TC is a candidate for removal.
- **Gap** — Neither unit nor E2E test covers this feature. Needs investigation.

### 6. Generate Review Report

Produce the full review report with actionable findings:

```markdown
## E2E Coverage Review: {package}

**Reviewed:** {timestamp}
**Scope:** {package-wide or scenario-id}
**Workflow version:** 2.1

### Summary

| Metric | Count |
|--------|-------|
| Package features | {n} |
| Unit test files | {n} |
| Unit assertions | {n} |
| E2E scenarios | {n} |
| E2E test cases | {n} |
| TCs with decision evidence | {n}/{total} |

### Coverage Matrix

{full matrix table from step 5}

### Overlap Analysis

TCs that may fail the E2E Value Gate (unit tests cover the same behavior):

| TC ID | Feature | Overlapping Unit Tests | Recommendation |
|-------|---------|----------------------|----------------|
| {id} | {feature} | {test files} | Remove — unit tests cover this fully |
| {id} | {feature} | {test files} | Keep — TC tests CLI pipeline, units test logic |

**Candidates for removal:** {n} TCs have full overlap with unit tests

### E2E Decision Record Coverage

| TC ID | Evidence Status | Missing Fields |
|-------|------------------|----------------|
| {id} | complete | none |
| {id} | missing | e2e-justification, unit-coverage-reviewed |

**Action:** Any TC with missing evidence should be updated in `scenario.yml` during the next rewrite cycle.

### Gap Analysis

Features with no E2E coverage that may need it:

| Feature | External Tools | Unit Coverage | E2E Needed? |
|---------|---------------|---------------|-------------|
| {feature} | {tools} | {yes/no} | {yes — requires real subprocess / no — unit tests sufficient} |

### Health Status

| TC ID | Last Verified | Status |
|-------|---------------|--------|
| {id} | {date} | Healthy / Outdated / Never verified |

**Outdated (> 30 days):** {n} TCs
**Never verified:** {n} TCs

### Consolidation Opportunities

TCs sharing the same CLI invocation that could be merged:

| CLI Command | TCs | Merged Assertions |
|-------------|-----|-------------------|
| {command} | {tc-a}, {tc-b} | {n} total verifications → {n} consolidated |

### Recommendations

1. {Priority recommendation based on overlap analysis}
2. {Recommendation based on gap analysis}
3. {Recommendation based on health status}

### Next Step

Run `ace-bundle wfi://e2e/plan-changes` to generate a concrete change plan.
```

## Example Invocations

**Review a package:**
```bash
ace-bundle wfi://e2e/review
```

**Review a single scenario:**
```bash
ace-bundle wfi://e2e/review
```

## Error Handling

### No Tests Found

If the package has no E2E tests:
```
No E2E tests found for {package}.

Unit test inventory was still performed. The package has {n} unit test files
with {n} assertions covering {n} features.

To create the first E2E test: `ace-bundle wfi://e2e/create`
```

### No Unit Tests Found

If the package has no unit tests:
```
Warning: No unit tests found for {package}. Coverage matrix will only show E2E coverage.
Consider adding unit tests before expanding E2E coverage.
```

### Package Not Found

If the package directory doesn't exist:
```
Package '{package}' not found.

Available packages:
{list of ace-* directories}
```