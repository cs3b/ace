---
workflow-id: wfi-run-e2e-tests
name: Run E2E Tests (Parallel)
description: Execute multiple E2E tests in parallel using Task tool subagents
version: "1.0"
source: ace-test-e2e-runner
---

# Run E2E Tests Workflow (Parallel Orchestrator)

This workflow executes multiple E2E tests in parallel using Task tool subagents. Each test runs independently and writes its own reports. The orchestrator aggregates results into a suite summary.

## Arguments

- `PACKAGE` (optional) - The package containing tests (e.g., `ace-lint`). If omitted with `--all`, runs all packages.
- `--all` (optional) - Run tests across all packages.
- `--sequential` (optional) - Force sequential execution instead of parallel.

## Architecture

```
/ace:run-e2e-tests ace-lint          (Orchestrator)
         │
         ├──► Task[Subagent 1] → /ace:run-e2e-test ace-lint MT-LINT-001
         ├──► Task[Subagent 2] → /ace:run-e2e-test ace-lint MT-LINT-002
         └──► Task[Subagent 3] → /ace:run-e2e-test ace-lint MT-LINT-003
                    │
                    ▼
         Reports in .cache/ace-test-e2e/ (parallel-safe via unique timestamps)
                    │
                    ▼
         Orchestrator reads reports → Generates suite summary
```

## Workflow Steps

### 1. Generate Suite ID

Generate a unique suite identifier for this run:

```bash
SUITE_ID="$(ace-timestamp encode)"
echo "Suite ID: $SUITE_ID"
```

Store this for the final report filename.

### 2. Discover Tests

Find all E2E test scenarios based on arguments:

**Single package:**
```bash
find {PACKAGE}/test/e2e -name "*.mt.md" 2>/dev/null | sort
```

**All packages (--all):**
```bash
find */test/e2e -name "*.mt.md" 2>/dev/null | sort
```

**Project root (no args, no --all):**
```bash
find test/e2e -name "*.mt.md" 2>/dev/null | sort
```

Parse each test file's frontmatter to extract:
- `test-id` - The test identifier (e.g., MT-LINT-001)
- `title` - Test title
- `priority` - Test priority level

Build a test manifest:

```markdown
| Test ID | Package | Title | Priority |
|---------|---------|-------|----------|
| MT-LINT-001 | ace-lint | Ruby Validator Fallback | P1 |
| MT-LINT-002 | ace-lint | Output Format Validation | P1 |
```

### 3. Launch Parallel Subagents

**CRITICAL: For parallel execution, spawn ALL subagents in a SINGLE message with multiple Task tool calls.**

For each test discovered, create a Task tool call:

```markdown
Task[subagent_type=general-purpose]:
  description: "Run E2E test {test-id}"
  prompt: |
    Run the E2E test scenario using the skill command.

    Execute: /ace:run-e2e-test {package} {test-id}

    After execution completes, return a structured summary:

    - **Test ID**: {test-id}
    - **Status**: pass | fail | partial
    - **Passed**: {count}
    - **Failed**: {count}
    - **Total**: {count}
    - **Report Paths**: (the timestamp-prefixed paths from .cache/ace-test-e2e/)
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
| MT-LINT-001 | pass | 8 | 0 | 8oig0h-ace-lint-MT-LINT-001 |
| MT-LINT-002 | fail | 3 | 2 | 8oig1k-ace-lint-MT-LINT-002 |
```

### 5. Read Metadata Files (Optional Detail)

For failed tests or detailed reporting, read the `.metadata.yml` files:

```bash
cat .cache/ace-test-e2e/{timestamp}-{package}-{test-id}.metadata.yml
```

Extract additional details:
- Duration
- Git commit
- Detailed pass/fail breakdown

### 6. Generate Suite Final Report

Write the suite summary report:

```bash
PROJECT_ROOT="$(pwd)"
SUITE_REPORT="$PROJECT_ROOT/.cache/ace-test-e2e/${SUITE_ID}-final-report.md"
```

**Report content:**

```markdown
---
suite-id: {SUITE_ID}
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
| MT-LINT-001 | Ruby Validator Fallback | Pass | 8 | 0 | 8 |
| MT-LINT-002 | Output Format Validation | Fail | 3 | 2 | 5 |

**Overall:** {total-passed}/{total-cases} test cases passed ({percentage}%)

## Failed Tests

### MT-LINT-002: Output Format Validation

**Failed Test Cases:**
- TC-003: Expected JSON output to include "errors" key
- TC-005: Exit code should be 1 for validation failures

**Report:** `.cache/ace-test-e2e/{timestamp}-ace-lint-MT-LINT-002.summary.r.md`

## Reports

All reports persisted to `.cache/ace-test-e2e/`:

| Test ID | Summary | Experience | Metadata |
|---------|---------|------------|----------|
| MT-LINT-001 | {ts}-ace-lint-MT-LINT-001.summary.r.md | {ts}-ace-lint-MT-LINT-001.experience.r.md | {ts}-ace-lint-MT-LINT-001.metadata.yml |
| MT-LINT-002 | {ts}-ace-lint-MT-LINT-002.summary.r.md | {ts}-ace-lint-MT-LINT-002.experience.r.md | {ts}-ace-lint-MT-LINT-002.metadata.yml |

**Suite Report:** `{SUITE_ID}-final-report.md`
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
| MT-LINT-001 | Pass | 8/8 |
| MT-LINT-002 | Fail | 3/5 |

### Overall: {total-passed}/{total-cases} passed ({percentage}%)

### Reports

Suite report: `.cache/ace-test-e2e/{SUITE_ID}-final-report.md`

Individual test reports in `.cache/ace-test-e2e/`:
- {timestamp}-ace-lint-MT-LINT-001.summary.r.md
- {timestamp}-ace-lint-MT-LINT-002.summary.r.md
```

## Example Invocations

**Run all tests in a package (parallel):**
```
/ace:run-e2e-tests ace-lint
```

**Run all tests across all packages:**
```
/ace:run-e2e-tests --all
```

**Force sequential execution:**
```
/ace:run-e2e-tests ace-lint --sequential
```

## Error Handling

### No Tests Found

If no tests are discovered:
```
No E2E tests found for {package}.

Use `/ace:create-e2e-test {package} {area}` to create tests.
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

| Aspect | /ace:run-e2e-test (singular) | /ace:run-e2e-tests (plural) |
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
