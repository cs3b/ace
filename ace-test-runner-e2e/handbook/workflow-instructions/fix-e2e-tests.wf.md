---
name: fix-e2e-tests
description: Diagnose and fix failing E2E tests systematically
allowed-tools: Read, Edit, Write, Bash, Grep, Glob
argument-hint: '[package] [test-id]'
doc-type: workflow
purpose: fix-e2e-tests workflow instruction
update:
  frequency: on-change
  last-updated: '2026-02-11'
---

# Fix E2E Tests Workflow

## Goal

Systematically diagnose and fix failing E2E tests — determining whether failures originate in **application code**, **test definitions**, or **test runner infrastructure**.

E2E tests are fundamentally different from unit tests: they are agent-executed via LLM, run in sandboxes, generate structured reports, and cost money per invocation. This workflow provides a cost-conscious, three-way diagnostic approach.

## Prerequisites

- E2E tests have been run and failures identified
- Reports available in `.cache/ace-test-e2e/` (summary.r.md, experience.r.md, metadata.yml)
- Package source code accessible
- `ace-test-e2e` CLI available

## Project Context Loading

- Read and follow: `ace-bundle wfi://load-project-context`
- Read E2E testing guide: `ace-bundle guide://e2e-testing`

**Before starting:**

1. Check recent changes: `git log --oneline -10`
2. Review E2E test configuration: `ace-test-runner-e2e/.ace-defaults/e2e-runner/config.yml`
3. Understand E2E conventions: `guide://e2e-testing`

## When to Use This Workflow

**Use this workflow for:**

- E2E test failures (any category: code, test, or runner)
- E2E test maintenance after application changes
- Flaky E2E tests requiring diagnosis
- Post-refactoring E2E test breakage

**NOT for:**

- Unit test failures (use `/ace:fix-tests`)
- New E2E test creation (use `/ace:create-e2e-test`)
- E2E test coverage review (use `/ace:review-e2e-tests`)
- General application bugs not causing E2E failures

## Step 1: Gather Failure Information

### 1.1 Locate Reports

Find the latest reports for the failing test:

```bash
# Find recent reports (sorted by modification time)
ls -lt .cache/ace-test-e2e/*-reports/ 2>/dev/null | head -20

# For a specific package/test, look for matching report dirs
ls -d .cache/ace-test-e2e/*-{short-pkg}-{short-id}-reports/ 2>/dev/null
```

### 1.2 Read Report Files

For each failing test, read the three report files:

1. **summary.r.md** — TC-level pass/fail status, overall result
2. **experience.r.md** — Agent-observed friction, root cause analysis, workarounds
3. **metadata.yml** — Run context (git commit, duration, provider, failed TC list)

```bash
# Example: read reports for a specific run
cat .cache/ace-test-e2e/{timestamp}-{pkg}-{id}-reports/summary.r.md
cat .cache/ace-test-e2e/{timestamp}-{pkg}-{id}-reports/experience.r.md
cat .cache/ace-test-e2e/{timestamp}-{pkg}-{id}-reports/metadata.yml
```

### 1.3 No Reports Available

If no reports exist, preview what would execute without running:

```bash
ace-test-e2e {package} {test-id} --dry-run
```

Or run the test to generate fresh reports:

```bash
ace-test-e2e {package} {test-id}
```

### 1.4 Gather Supporting Context

- Check git history for changes to the package under test: `git log --oneline -20 -- {package}/`
- Check git history for changes to the test itself: `git log --oneline -10 -- {package}/test/e2e/`
- Check if unit tests for the same feature pass: `ace-test {package}`

## Step 2: Diagnose Root Cause (Three-Way Classification)

For each failing TC, classify into one of three categories:

### Category A: Code Issue (Application Code Is Wrong)

**Signals:**

- Test steps executed correctly but assertions failed because output/behavior changed
- Recent git commits modified code under test
- Other (non-E2E) tests for the same feature also fail
- Error messages point to logic bugs, not test setup
- Exit codes changed from expected values

**Diagnosis steps:**

1. Compare the TC's expected output with actual output from the report
2. Check `git log` for recent changes to the code under test
3. Run unit tests for the same feature: `ace-test {package}`
4. Read the application code to confirm the bug

**Action:** Fix the application code, then re-verify with targeted TC run.

### Category B: Test Issue (E2E Test Definition Is Wrong)

**Signals:**

- CLI interface changed (new flags, renamed options, different output format)
- Test references paths/files/configs that no longer exist
- Expected output format doesn't match current tool behavior
- Fixtures are stale or incomplete (TS-format: scenario.yml or fixtures/)
- Test steps are in wrong order or missing steps
- Test was written for an older version of the tool

**Diagnosis steps:**

1. Compare the test definition with the current CLI help: `{tool} --help`
2. Check if referenced files/paths still exist
3. Verify expected output matches current tool behavior by running manually
4. For TS-format: check `scenario.yml` setup directives and `fixtures/` contents

**Action:** Update the test definition (`TC-*.tc.md` and/or `scenario.yml`).

### Category C: Runner/Infrastructure Issue (Test Execution Machinery Is Broken)

**Signals:**

- Sandbox setup failed (SetupExecutor errors in experience report)
- Report parsing errors (ResultParser/SkillResultParser failures)
- TC fidelity validation errors (agent executed wrong TCs)
- Provider errors (LLM timeout, API errors, model unavailable)
- Sandbox isolation violations (tests ran in main repo)
- `ace-test-e2e` CLI errors before test execution starts

**Diagnosis steps:**

1. Check experience.r.md for infrastructure-level friction
2. Check metadata.yml for provider errors or unusual durations
3. Look for SetupExecutor errors: `grep -r "SetupExecutor" .cache/ace-test-e2e/`
4. Run runner unit tests: `ace-test ace-test-runner-e2e`

**Action:** Fix the runner code in `ace-test-runner-e2e/lib/`.

### Decision Tree

```
TC failed
├── Did the agent execute the right steps?
│   ├── NO → Category C (runner/infrastructure)
│   │   └── Check: sandbox setup, TC fidelity, provider errors
│   └── YES → Did the tool produce expected output?
│       ├── YES (but assertion wrong) → Category B (test issue)
│       │   └── Check: stale expected values, changed format
│       └── NO (tool behavior changed) → Was the change intentional?
│           ├── YES (refactoring/feature) → Category B (test needs update)
│           └── NO (regression) → Category A (code bug)
```

## Step 3: Fix One at a Time (Iterative Loop)

**Priority order:** Fix Category C first (unblocks all tests), then A (code bugs), then B (test updates).

For each failing TC:

### 3.1 Pick the Next Failing TC

Start with the highest-priority category. Within a category, pick the TC most likely to unblock others.

### 3.2 Apply the Fix

**Category A (code fix):**

1. Identify the bug in application code
2. Fix the code
3. Update or add unit tests to cover the fix
4. Run unit tests: `ace-test {package}`

**Category B (test fix):**

1. Update the test definition to match current behavior
2. Edit the relevant `TC-*.tc.md` and/or `scenario.yml`
3. Update fixtures if needed

**Category C (runner fix):**

1. Fix the runner code in `ace-test-runner-e2e/lib/`
2. Run runner unit tests: `ace-test ace-test-runner-e2e`
3. Verify the fix doesn't break other runner functionality

### 3.3 Re-Run the Specific TC

```bash
# Re-run only the fixed TC (cost-conscious: single TC, not full suite)
ace-test-e2e {package} {test-id} --test-cases TC-NNN
```

### 3.4 Verify the Fix

Read the updated report to confirm the TC passes:

```bash
# Check the latest report for this TC
ls -t .cache/ace-test-e2e/*-reports/summary.r.md | head -1 | xargs cat
```

### 3.5 Loop

Repeat steps 3.1–3.4 until all failing TCs are resolved.

## Step 4: Final Verification

After fixing all individual TCs, run a broader verification:

```bash
# Option A: Re-run only previously-failed TCs
ace-test-e2e {package} {test-id} --only-failures

# Option B: Run the full test scenario
ace-test-e2e {package} {test-id}
```

**If runner code was changed (Category C):**

```bash
# Also verify runner unit tests still pass
ace-test ace-test-runner-e2e
```

## Step 5: Cost-Conscious Re-run Strategy

E2E tests cost money per invocation. Follow these rules:

- **Never** blindly re-run all TCs; target specific failures
- **Use `--test-cases TC-NNN`** for individual TC re-runs during the fix loop
- **Use `--only-failures`** for final verification of all previously-failed TCs
- **Use `--dry-run`** to preview what would execute before committing to a full run
- **Batch related fixes** before re-running — if 3 TCs fail for the same reason, fix all 3 then re-run together

```bash
# Preview (free)
ace-test-e2e {package} {test-id} --dry-run

# Single TC (cheapest verification)
ace-test-e2e {package} {test-id} --test-cases TC-002

# Multiple specific TCs
ace-test-e2e {package} {test-id} --test-cases TC-002,TC-005

# Only failures from last run
ace-test-e2e {package} {test-id} --only-failures

# Full suite (most expensive — use only for final verification)
ace-test-e2e {package} {test-id}
```

## Common E2E Failure Patterns

### Pattern: Exit Code Mismatch

**Symptom:** TC expected exit code 0 but got 1 (or vice versa)
**Common causes:**

- Application added new validation that rejects previously-valid input
- Error handling changed (exception → graceful error, or reverse)
- Flag behavior changed (e.g., `--fix` now exits non-zero on partial fix)

**Diagnosis:** Run the command manually and check what changed.

### Pattern: Output Format Changed

**Symptom:** TC expected specific output text but got different formatting
**Common causes:**

- Report format updated (new columns, changed headers)
- Verbose/quiet mode behavior changed
- Color/emoji added or removed

**Diagnosis:** Compare expected output in test with actual output. Usually Category B.

### Pattern: Sandbox Setup Failure

**Symptom:** Test never reaches TC execution; errors during environment setup
**Common causes:**

- `ace-test-e2e-sh` wrapper broken
- `SetupExecutor` (TS-format) can't find fixtures
- Git init fails in sandbox
- Missing prerequisite tools

**Diagnosis:** Check experience.r.md for setup-phase errors. Category C.

### Pattern: Stale Fixtures

**Symptom:** TC fails because test data doesn't match current schema/format
**Common causes:**

- Application config format changed
- Required fields added to input files
- File naming conventions updated

**Diagnosis:** Compare fixture files with current application expectations. Category B.

### Pattern: TC Fidelity Violation

**Symptom:** Agent executed different steps than what the TC specifies
**Common causes:**

- TC instructions are ambiguous
- Agent model interpreted steps differently
- TC has conflicting instructions

**Diagnosis:** Compare TC definition with agent's actual execution in experience report. Usually Category B (improve TC clarity) or C (fidelity validation bug).

### Pattern: Provider/Timeout Error

**Symptom:** Test execution aborted due to API error or timeout
**Common causes:**

- LLM provider rate limiting
- Model unavailable or overloaded
- TC takes longer than configured timeout

**Diagnosis:** Check metadata.yml for provider errors and duration. Category C (retry or adjust timeout).

## Quick Troubleshooting Decision Tree

```
Failure Type → First Action

Sandbox setup failed       → Check ace-test-e2e-sh and SetupExecutor (Category C)
Agent executed wrong TCs   → Check TC fidelity validation (Category C)
Provider/API error         → Retry once; if persistent, check config (Category C)
Exit code mismatch         → git log on code under test (Category A or B)
Output format mismatch     → Compare current vs expected output (Category B)
Missing file/path          → Check if paths still exist (Category B)
Timeout                    → Check if TC is too broad; split or increase timeout (Category B or C)
All TCs fail same way      → Likely Category A (code regression) or C (infrastructure)
Single TC fails            → Likely Category B (test needs update)
```

## Output / Success Criteria

- All failing TCs now pass
- Root cause documented per TC (which category and what was wrong)
- No regressions in other TCs
- If code was fixed (Category A): unit tests also updated and passing
- If test was fixed (Category B): follows current E2E conventions (see `guide://e2e-testing`)
- If runner was fixed (Category C): `ace-test ace-test-runner-e2e` passes
- Cost-conscious approach maintained (no unnecessary full-suite reruns)
