---
workflow-id: wfi-run-e2e-tests
name: e2e/run-batch
description: Execute multiple E2E tests in parallel using Task tool subagents
version: "1.1"
source: ace-test-runner-e2e
---

# Run E2E Tests Workflow (Parallel Orchestrator)

This workflow executes multiple E2E tests in parallel using Task tool subagents. Each test runs independently and writes its own reports. The orchestrator aggregates results into a suite summary.

## Arguments

- `PACKAGE` (optional) - The package containing tests (e.g., `ace-lint`). If omitted with `--all`, runs all packages.
- `--all` (optional) - Run tests across all packages.
- `--sequential` (optional) - Force sequential execution instead of parallel.
- `--tags TAG,...` (optional) - Include only scenarios matching any specified tag (OR semantics).
- `--exclude-tags TAG,...` (optional) - Exclude scenarios matching any specified tag (OR semantics).

## Execution Environment Guardrail

- Do **not** run `ace-test-e2e` / `ace-test-e2e-suite` autonomously in constrained or uncertain environments.
- Treat batch execution as user-invoked verification by default.
- Provide exact run commands unless the user explicitly requests execution and confirms environment fidelity.

## Architecture

```
/ace-e2e-runs ace-lint          (Orchestrator)
         │
         ├──► Task[Subagent 1] → /ace-e2e-run ace-lint TS-LINT-001
         ├──► Task[Subagent 2] → /ace-e2e-run ace-lint TS-LINT-002
         ├──► Task[Subagent 3] → /ace-e2e-run ace-lint TS-LINT-003
         └──► Task[Subagent 4] → /ace-e2e-run ace-lint TS-LINT-004
                    │
                    ▼
         Reports in .ace-local/test-e2e/ (parallel-safe via unique timestamps)
                    │
                    ▼
         Orchestrator reads reports → Generates suite summary
```

## Workflow Steps

### 1. Generate Suite ID

Generate a unique suite identifier for this run:

```bash
SUITE_ID="$(ace-b36ts encode)"
echo "Suite ID: $SUITE_ID"
```

Store this for the final report filename.

### 2. Discover Tests

Find all E2E test scenarios based on arguments:

**Single package:**
```bash
find {PACKAGE}/test/e2e -name "scenario.yml" -path "*/TS-*" 2>/dev/null | sort
```

**All packages (--all):**
```bash
find */test/e2e -name "scenario.yml" -path "*/TS-*" 2>/dev/null | sort
```

**Project root (no args, no --all):**
```bash
find test/e2e -name "scenario.yml" -path "*/TS-*" 2>/dev/null | sort
```

Parse each test file's frontmatter to extract:
- `test-id` - The test identifier (e.g., `TS-LINT-001`)
- `title` - Test title
- `priority` - Test priority level

Build a test manifest:

```markdown
| Test ID | Package | Title | Priority |
|---------|---------|-------|----------|
| TS-LINT-001 | ace-lint | Ruby Validator Fallback | P1 |
| TS-LINT-002 | ace-lint | JSON Report Generation | P1 |
| TS-LINT-003 | ace-lint | Skill Validation | P2 |
```

### 3. Launch Parallel Subagents

**CRITICAL: For parallel execution, spawn ALL subagents in a SINGLE message with multiple Task tool calls.**

For each test discovered, create a Task tool call:

```markdown
Task[subagent_type=general-purpose]:
  description: "Run E2E test {test-id}"
  prompt: |
    Run the E2E test scenario using the skill command.

    Execute: /ace-e2e-run {package} {test-id}

    After execution completes, return a structured summary:

    - **Test ID**: {test-id}
    - **Status**: pass | fail | partial
    - **Passed**: {count}
    - **Failed**: {count}
    - **Total**: {count}
    - **Report Paths**: (the timestamp-prefixed paths from .ace-local/test-e2e/)
    - **Issues**: Brief description or "None"

    Do not include full report contents - just paths and summary counts.
```

**Parallel execution:** Send all Task tool calls in ONE message. The Task tool spawns them concurrently.

**Sequential execution (--sequential flag):** Send Task tool calls one at a time, waiting for each to complete.

### 4. Collect Subagent Results

As each subagent completes, capture its return summary:

```markdown
## Subagent Results

| Test ID | Status | Passed | Failed | Report Path |
|---------|--------|--------|--------|-------------|
| TS-LINT-001 | pass | 8 | 0 | 8oig0h-lint-ts001 |
| TS-LINT-002 | fail | 3 | 2 | 8oig1k-lint-ts002 |
```

### 5. Read Metadata Files (Optional Detail)

For failed tests or detailed reporting, read the `metadata.yml` files from the reports folder:

```bash
cat .ace-local/test-e2e/{timestamp}-{short-pkg}-{short-id}-reports/metadata.yml
```

Extract additional details:
- Duration
- Git commit
- Detailed pass/fail breakdown

### 6. Generate Suite Final Report

Write the suite summary report:

```bash
PROJECT_ROOT="$(pwd)"
FINAL_TS="$(ace-b36ts encode)"
SUITE_REPORT="$PROJECT_ROOT/.ace-local/test-e2e/${FINAL_TS}-final-report.md"
```

**Report content:**

```markdown
---
suite-id: {SUITE_ID}
final-ts: {FINAL_TS}
package: {package}
execution-mode: parallel|sequential
status: pass|fail|partial
tests-run: {count}
executed: {timestamp}
agent: {agent-name}
---

# E2E Test Suite Report

**Suite ID:** {SUITE_ID}
**Package:** {package}
**Execution Mode:** parallel|sequential
**Executed:** {timestamp}
**Agent:** {agent-name}

## Summary

| Test ID | Title | Status | Passed | Failed | Total |
|---------|-------|--------|--------|--------|-------|
| TS-LINT-001 | Ruby Validator Fallback | Pass | 8 | 0 | 8 |
| TS-LINT-002 | JSON Report Generation | Fail | 3 | 2 | 5 |

**Overall:** {total-passed}/{total-cases} test cases passed ({percentage}%)

## Failed Tests

### TS-LINT-002: JSON Report Generation

**Failed Test Cases:**
- TC-003: Expected JSON output to include "errors" key
- TC-005: Exit code should be 1 for validation failures

**Report:** `.ace-local/test-e2e/{timestamp}-lint-ts002-reports/summary.r.md`

## Reports

All reports persisted to `.ace-local/test-e2e/`:

| Test ID | Sandbox | Reports Folder |
|---------|---------|----------------|
| TS-LINT-001 | {ts}-lint-ts001/ | {ts}-lint-ts001-reports/ |
| TS-LINT-002 | {ts}-lint-ts002/ | {ts}-lint-ts002-reports/ |

Each reports folder contains: `summary.r.md`, `experience.r.md`, `metadata.yml`

**Suite Report:** `{FINAL_TS}-final-report.md` (only final report at top level)

## Agent Experience Insights

Aggregated feedback from {tests-run} test executions.

### Friction Summary

| Category | Count | Tests Affected |
|----------|-------|----------------|
| Documentation Gaps | {n} | {test-ids} |
| Tool Behavior Issues | {n} | {test-ids} |
| API/CLI Friction | {n} | {test-ids} |

### Improvement Suggestions

**High Priority:**
- [ ] {suggestion from test with most friction}
- [ ] {suggestion affecting multiple tests}

**Medium Priority:**
- [ ] {suggestion from single test}

### Workarounds Used

| Issue | Workaround | Tests |
|-------|------------|-------|
| {issue description} | {workaround used} | {test-ids} |

### Positive Observations

- {positive observation from test 1}
- {positive observation from test 2}
```

### 7. Display Summary

Present the execution summary to the user:

```markdown
## E2E Test Suite Execution Complete

**Suite ID:** {SUITE_ID}
**Package:** {package}
**Mode:** parallel|sequential
**Tests Run:** {count}

### Results

| Test ID | Status | Passed/Total |
|---------|--------|--------------|
| TS-LINT-001 | Pass | 8/8 |
| TS-LINT-002 | Fail | 3/5 |

### Overall: {total-passed}/{total-cases} passed ({percentage}%)

### Reports

Suite report: `.ace-local/test-e2e/{FINAL_TS}-final-report.md`

Individual test reports in `.ace-local/test-e2e/`:
- {timestamp}-lint-ts001-reports/
- {timestamp}-lint-ts002-reports/
```

## Example Invocations

**Run all tests in a package (parallel):**
```
/ace-e2e-runs ace-lint
```

**Run all tests across all packages:**
```
/ace-e2e-runs --all
```

**Force sequential execution:**
```
/ace-e2e-runs ace-lint --sequential
```

## Error Handling

### No Tests Found

If no tests are discovered:
```
No E2E tests found for {package}.

Use `/ace-e2e-create {package} {area}` to create tests.
```

### Subagent Failure

If a subagent fails to complete:
1. Record the failure with available information
2. Continue collecting results from other subagents
3. Mark the test as "incomplete" in the suite report
4. Include error details in the summary

### Partial Results

If some tests pass and others fail:
1. Suite status is "partial" or "fail" depending on failure count
2. All individual reports are still written
3. Suite report highlights failures for investigation

## Comparison with Single Test Execution

| Aspect | /ace-e2e-run (singular) | /ace-e2e-runs (plural) |
|--------|------------------------------|------------------------------|
| Execution | Sequential in single agent | Parallel via subagents |
| Scope | Single test or all in package | Package or all packages |
| Reports | Individual test reports | Individual + suite report |
| Use case | Single test verification | Full test suite runs |

## Parallel Execution Benefits

1. **Faster execution** - Tests run concurrently
2. **Isolated contexts** - Each subagent has clean state
3. **Robust reporting** - File-based reports survive failures
4. **Scalable** - Add more tests without linear time increase
