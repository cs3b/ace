---
workflow-id: wfi-manage-e2e-tests
name: Manage E2E Tests
description: Orchestrate E2E test lifecycle - review, create, run, and maintain tests
version: "1.0"
source: ace-test-e2e-runner
---

# Manage E2E Tests Workflow

This workflow orchestrates the full E2E test lifecycle by coordinating review, creation, and execution of tests.

## Arguments

- `PACKAGE` (optional) - The package to manage (e.g., `ace-lint`). If omitted, manages all packages.
- `--since <commit/date>` (optional) - Analyze changes since this commit or date. Default: 30 days ago.
- `--dry-run` (optional) - Show management plan without executing changes.
- `--run-tests` (optional) - Run all tests after management operations.

## Workflow Steps

### 1. Review Existing Tests

**Delegate to review workflow:**

Invoke `/ace:review-e2e-tests {PACKAGE}` or `/ace:review-e2e-tests --all` to:
- Discover all existing tests
- Analyze health status
- Identify coverage gaps

Capture the review results for use in planning.

### 2. Analyze Recent Changes

Determine the baseline for change analysis:

**If --since provided:**
```bash
# For commit hash
git rev-parse --verify {since}

# For date
git log --oneline --after="{since}" -- {PACKAGE}/lib/ {PACKAGE}/bin/ | head -20
```

**Default (30 days):**
```bash
git log --oneline --since="30 days ago" -- {PACKAGE}/lib/ {PACKAGE}/bin/
```

**Get changed files:**
```bash
git diff --name-only {since}..HEAD -- {PACKAGE}/lib/ {PACKAGE}/bin/
```

Build a list of:
- Files changed since baseline
- Commits with their messages
- New features or significant changes

### 3. Correlate Tests with Changes

Build a correlation matrix:

| Test ID | Test Area | Related Files | Change Status |
|---------|-----------|---------------|---------------|
| MT-LINT-001 | lint | lib/lint/*.rb | Changed |
| MT-LINT-002 | report | lib/report/*.rb | Unchanged |

For each test:
1. Parse the test's area and scope
2. Identify related source files
3. Check if related files have changes since test's `last-verified`
4. Mark correlation status

### 4. Generate Management Plan

Based on review results and change correlation, categorize tests:

**UPDATE (re-verify):**
- Tests with related code changes since `last-verified`
- Outdated tests (> 30 days old)
- Tests that failed structure validation

**CREATE:**
- Coverage gaps identified in review
- New features without tests
- Areas requested by user

**ARCHIVE:**
- Tests for deprecated/removed features
- Duplicate coverage (same area tested multiple times)
- Tests marked as obsolete in notes

**KEEP:**
- Current tests with no related changes
- Recently verified tests
- Tests covering stable features

### 5. Present Plan to User

Display the management plan for confirmation:

```markdown
## E2E Test Management Plan

**Package:** {package}
**Analysis Period:** {since} to now
**Mode:** {dry-run | execute}

### Summary

| Action | Count | Tests |
|--------|-------|-------|
| UPDATE | 2 | MT-LINT-001, MT-LINT-002 |
| CREATE | 1 | New test for config validation |
| ARCHIVE | 0 | - |
| KEEP | 3 | MT-LINT-003, ... |

### UPDATE (Re-verify)

These tests have related code changes and should be re-verified:

| Test ID | Reason | Related Changes |
|---------|--------|-----------------|
| MT-LINT-001 | Code changed | lib/lint/validator.rb |
| MT-LINT-002 | Outdated (45 days) | - |

### CREATE (New Tests)

Coverage gaps to address:

| Area | Reason | Suggested Context |
|------|--------|-------------------|
| CONFIG | No coverage | Config file parsing and validation |

### ARCHIVE (Deprecate)

Tests to move to archive:

| Test ID | Reason |
|---------|--------|
| (none) | |

### KEEP (No Action)

| Test ID | Status |
|---------|--------|
| MT-LINT-003 | Current, no changes |

---

**Proceed with this plan?** (Confirm to execute, or provide modifications)
```

**If --dry-run:** Stop here after presenting the plan.

### 6. Execute Plan (if confirmed)

Execute each action in the plan:

**UPDATE actions:**
For each test to re-verify:
```
/ace:run-e2e-test {package} {test-id}
```

Collect results and update `last-verified` dates.

**CREATE actions:**
For each new test to create:
```
/ace:create-e2e-test {package} {area} --context "{suggested context}"
```

**ARCHIVE actions:**
For each test to archive:
```bash
mkdir -p {PACKAGE}/test/e2e/archive
mv {PACKAGE}/test/e2e/{test-file} {PACKAGE}/test/e2e/archive/
```

### 7. Run All Tests (if --run-tests)

If `--run-tests` flag is provided:

```
/ace:run-e2e-test {package}
```

This runs all tests in the package and generates a combined report.

### 8. Generate Summary Report

Produce a final summary:

```markdown
## E2E Test Management Summary

**Package:** {package}
**Executed:** {timestamp}

### Actions Completed

| Action | Planned | Completed | Status |
|--------|---------|-----------|--------|
| UPDATE | 2 | 2 | All passed |
| CREATE | 1 | 1 | Created |
| ARCHIVE | 0 | 0 | - |

### Updated Tests

| Test ID | Previous Verified | New Verified | Result |
|---------|------------------|--------------|--------|
| MT-LINT-001 | 2025-12-15 | 2026-01-19 | Pass |
| MT-LINT-002 | 2025-12-01 | 2026-01-19 | Pass |

### Created Tests

| Test ID | File | Status |
|---------|------|--------|
| MT-CONFIG-001 | config-validation.mt.md | Created - needs customization |

### Test Run Results (if --run-tests)

| Test ID | Status |
|---------|--------|
| MT-LINT-001 | Pass |
| MT-LINT-002 | Pass |
| MT-CONFIG-001 | Not run (new) |

**Overall: {passed}/{total} tests passing**

### Recommendations

1. {Next steps based on results}
2. {Any manual follow-up needed}
```

## Example Invocations

**Review and manage a package (dry-run):**
```
/ace:manage-e2e-tests ace-lint --dry-run
```

Shows the management plan without making changes.

**Execute management plan:**
```
/ace:manage-e2e-tests ace-lint
```

Reviews, correlates changes, presents plan, and executes after confirmation.

**Manage with specific timeframe:**
```
/ace:manage-e2e-tests ace-lint --since "2026-01-01"
```

Analyzes changes since January 1st, 2026.

**Full lifecycle with test execution:**
```
/ace:manage-e2e-tests ace-lint --run-tests
```

Manages tests and runs all tests at the end.

**Manage all packages:**
```
/ace:manage-e2e-tests --all --dry-run
```

Reviews all packages and shows a combined management plan.

## Orchestration Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    /ace:manage-e2e-tests                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              1. /ace:review-e2e-tests                       │
│                 (Analyze health & coverage)                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              2. Analyze git changes                         │
│                 (Correlate tests with code)                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              3. Generate & present plan                     │
│                 (UPDATE / CREATE / ARCHIVE / KEEP)          │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
              (dry-run)           (execute)
                    │                   │
                    ▼                   ▼
              ┌─────────┐    ┌─────────────────────┐
              │  Stop   │    │  Execute actions:   │
              └─────────┘    │  - /ace:run-e2e-test│
                             │  - /ace:create-...  │
                             │  - Archive files    │
                             └─────────────────────┘
                                        │
                                        ▼
                             ┌─────────────────────┐
                             │  (if --run-tests)   │
                             │  /ace:run-e2e-test  │
                             │  {package}          │
                             └─────────────────────┘
                                        │
                                        ▼
                             ┌─────────────────────┐
                             │  Summary report     │
                             └─────────────────────┘
```

## Error Handling

### No Tests Found

If no tests exist for the package:
```
No E2E tests found for {package}.

Would you like to create the first test?
- Use `/ace:create-e2e-test {package} {AREA}` to create a test
```

### Execution Failures

If a test re-verification fails:
1. Record the failure
2. Continue with remaining actions
3. Include failure in summary report
4. Do not update `last-verified` for failed tests

### User Cancellation

If user declines the plan:
1. Ask for modifications
2. Regenerate plan with changes
3. Or exit without changes
