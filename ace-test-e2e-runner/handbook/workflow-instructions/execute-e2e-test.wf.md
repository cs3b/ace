---
workflow-id: wfi-execute-e2e-test
name: Execute E2E Test (Pre-populated Sandbox)
description: Execute test cases in a pre-populated sandbox with reporting
version: "1.0"
source: ace-test-e2e-runner
---

# Execute E2E Test Workflow

This workflow guides an agent through executing test cases in a **pre-populated sandbox**. The sandbox was created by `SetupExecutor` in Ruby — this workflow handles only execution and reporting.

## Arguments

- `PACKAGE` (required) - The package containing the test (e.g., `ace-lint`)
- `TEST_ID` (required) - The test identifier (e.g., `TS-LINT-001`)
- `--sandbox SANDBOX_PATH` (required) - Path to the pre-populated sandbox directory
- `--run-id RUN_ID` (optional) - Pre-generated timestamp ID for deterministic report paths
- `--env KEY=VALUE[,...]` (optional) - Comma-separated environment variables to set before execution (e.g., `--env PROJECT_ROOT_PATH=/code,MODE=test`)
- `TEST_CASES` (optional) - Comma-separated list of test case IDs to execute (e.g., `TC-001,tc-003,002`). When provided, only the specified test cases are executed; all others are skipped.

  **Accepted formats:**
  - `TC-001` - already normalized
  - `tc-001` - uppercased to `TC-001`
  - `001` - prefix added: `TC-001`
  - `1` - zero-padded and prefixed: `TC-001`
  - `TC-1` - zero-padded: `TC-001`

  When omitted, all test cases in the scenario are executed (default behavior).

## Subagent Mode

When invoked as a subagent (via Task tool from `/ace:run-e2e-tests` orchestrator), this workflow operates with special considerations:

### Context Isolation

- Each subagent runs in a clean context with no shared state
- Timestamp IDs ensure unique report paths (no collisions with parallel runs)
- All reports are written to disk, not returned inline

### Return Contract

After completing all steps, return a **minimal structured summary** instead of verbose output:

```markdown
- **Test ID**: {test-id}
- **Status**: pass | fail | partial
- **Passed**: {count}
- **Failed**: {count}
- **Total**: {count}
- **Report Paths**: {timestamp}-{short-pkg}-{short-id}.*
- **Issues**: Brief description or "None"
```

**Do NOT include:**
- Full report contents (they're on disk)
- Detailed test case output
- Environment setup logs

The orchestrator aggregates these summaries and reads report files as needed.

### Report-First Design

1. Write all reports to `.cache/ace-test-e2e/` (steps 3.1-3.3)
2. Return only paths and summary counts
3. Orchestrator reads files for detailed aggregation

## TC-Level Execution Mode

When invoked with `--tc-mode`, this workflow operates in TC-level mode where only a single test case is executed. Steps 1-2 of the standard workflow are skipped.

### TC-Level Arguments

- `PACKAGE` (required) - Package name (e.g., `ace-lint`)
- `TEST_ID` (required) - Parent scenario ID (e.g., `TS-LINT-001`)
- `TC_ID` (required) - Test case ID (e.g., `TC-001`)
- `--tc-mode` (required) - Activates TC-level execution mode
- `--sandbox SANDBOX_PATH` (required) - Path to pre-populated sandbox directory
- `--run-id RUN_ID` (optional) - Pre-generated timestamp ID for report paths

### TC-Level Execution Steps

1. **Verify sandbox** — Confirm `SANDBOX_PATH` exists and contains the expected test environment
2. **Enter sandbox** — `cd SANDBOX_PATH`
3. **Execute TC steps** — Follow the test case instructions (objective, steps, expected results)
4. **Write per-TC reports** — Generate `summary.r.md`, `experience.r.md`, `metadata.yml` in `{RUN_ID}-{pkg}-{scenario}-{tc}-reports/`
5. **Return TC-level contract:**

```markdown
- **Test ID**: {TEST_ID}
- **TC ID**: {TC_ID}
- **Status**: pass | fail
- **Report Paths**: {run-id}-{pkg}-{scenario}-{tc}-reports/*
- **Issues**: Brief description or "None"
```

### TC-Level Rules

- Do NOT create or modify sandbox setup — it is already prepared by `SetupExecutor`
- Do NOT run setup scripts or environment initialization
- Execute only the steps described in the test case content
- Report actual results even if they differ from expected

---

## Sandbox Rules

- Do NOT create or modify the sandbox setup — it is already prepared by `SetupExecutor`
- Do NOT run environment setup, prerequisite checks, or test data creation
- The sandbox directory and fixtures are already in place
- Focus exclusively on test case execution and reporting

## Workflow Steps

### 1. Set Up Execution Environment

Parse arguments and prepare for execution:

1. **Set environment variables** — Parse `--env` and export each `KEY=VALUE`
2. **Enter sandbox** — `cd SANDBOX_PATH`
3. **Set TIMESTAMP_ID** — Use `--run-id` value if provided, otherwise generate with `ace-timestamp encode`

**Expected Variables After Setup:**
- `SANDBOX_PATH` - The pre-populated sandbox directory (current working directory)
- `TIMESTAMP_ID` - Unique identifier for this test run
- Any variables from `--env` (e.g., `PROJECT_ROOT_PATH`, `MODE`)

### 2. Discover and Filter Test Cases

Discover `.tc.md` files in the scenario directory within the sandbox:

```bash
find "${SANDBOX_PATH}" -name "*.tc.md" 2>/dev/null | sort
```

**After discovery, explicitly list all found test cases before proceeding:**

```
Found N test case files:
- TC-001: {filename}
- TC-002: {filename}
...
```

> **CRITICAL TC FIDELITY RULE:** You MUST execute ONLY the test cases defined in `.tc.md` files. Do NOT create, modify, or invent additional test cases. Do NOT substitute your own test scenarios for the defined ones. Each `.tc.md` file contains specific steps you must follow exactly.

If `TEST_CASES` argument was provided, parse and normalize the filter:

**Step 1: Parse TEST_CASES argument**

Split the comma-separated list into individual IDs:

```bash
IFS=',' read -ra RAW_CASES <<< "$TEST_CASES"
```

**Step 2: Normalize test case IDs**

Each ID must be normalized to the canonical `TC-NNN` format (uppercase, zero-padded to 3 digits):

```bash
normalize_tc_id() {
  local id="$1"
  id="$(echo "$id" | xargs)"
  id="$(echo "$id" | tr '[:lower:]' '[:upper:]')"
  local num
  if [[ "$id" =~ ^TC-([0-9]+)$ ]]; then
    num="${BASH_REMATCH[1]}"
  elif [[ "$id" =~ ^([0-9]+)$ ]]; then
    num="${BASH_REMATCH[1]}"
  else
    echo "ERROR: Invalid test case ID format: '$1'" >&2
    return 1
  fi
  printf "TC-%03d" "$((10#$num))"
}

declare -A SEEN_CASES
FILTERED_CASES=()
for raw_id in "${RAW_CASES[@]}"; do
  normalized="$(normalize_tc_id "$raw_id")" || exit 1
  if [[ -z "${SEEN_CASES[$normalized]+x}" ]]; then
    SEEN_CASES[$normalized]=1
    FILTERED_CASES+=("$normalized")
  fi
done

echo "Test cases to execute: ${FILTERED_CASES[*]}"
```

When `TEST_CASES` is empty or not provided, execute all discovered test cases (default behavior).

### 3. Execute Test Cases

> **CRITICAL: Use `ace-test-e2e-sh` for ALL test case commands**
>
> Each bash block runs in a fresh shell. Use `ace-test-e2e-sh "$SANDBOX_PATH"` to ensure
> every command executes inside the sandbox. See syntax examples below.
>
> **Single command:** `ace-test-e2e-sh "$SANDBOX_PATH" git add README.md`
> **Multi-command block:** Pass via stdin:
> ```
> ace-test-e2e-sh "$SANDBOX_PATH" bash << 'SANDBOX'
> cat > file.txt << 'EOF'
> content
> EOF
> git add file.txt
> SANDBOX
> ```

**Determine execution scope:**

- If `FILTERED_CASES` is set (from step 2), execute **only** test cases whose IDs are in the `FILTERED_CASES` array. Skip all other test cases.
- If `FILTERED_CASES` is not set, execute **all** test cases in the scenario (default behavior).

For each test case (TC-NNN):

1. **Check filter** - If `FILTERED_CASES` is set and this test case ID is not in the array, **skip** this test case entirely. Log: `Skipping TC-NNN (not in filter)`.
2. **Read the objective** - Understand what this test verifies
3. **Execute the steps** - Run each command in sequence
4. **Capture results** - Record:
   - Actual exit code
   - Command output
   - Any error messages
5. **Compare to expected** - Check against expected results
6. **Record status** - Pass or Fail

Report each test case result immediately after execution.

**Self-check:** Before writing reports, verify your result table has exactly N rows matching the N `.tc.md` files found in Step 2 (or the filtered subset). If you have more or fewer results than expected, STOP and re-examine — you may have skipped a test case or invented one.

**During execution, track friction points** for the Agent Experience Report:
- Documentation gaps discovered
- Unexpected tool behavior
- Confusing error messages
- Workarounds needed
- Positive observations

### 4. Write Reports to Disk

After test execution completes (pass or fail), write three report files to a reports subfolder.

**Important:** Replace all `{placeholder}` values with actual data before writing. Do not copy placeholders literally.

**Set up report paths (reports subfolder):**
```bash
REPORT_DIR="${SANDBOX_PATH}-reports"
mkdir -p "$REPORT_DIR"
```

**Error Handling:**
- If the cache directory doesn't exist, create it with `mkdir -p "$(dirname "$SANDBOX_PATH")"`
- If write fails (permissions), report the error and suggest manual intervention
- For partial test completion, still write reports with status "partial" or "incomplete"

#### 4.1 Write summary report (summary.r.md)

**Note:** When test case filtering is active (`FILTERED_CASES` is set), include **only** the executed test cases in the Results Summary table.

```bash
cat > "${REPORT_DIR}/summary.r.md" << 'EOF'
---
test-id: {test-id}
package: {package}
agent: {agent-name}
executed: {timestamp}
status: {status}  # One of: pass, fail, partial, incomplete
passed: {count}
failed: {count}
total: {count}
filtered: {true|false}
---

# E2E Test Report: {test-id}

## Test Information

| Field | Value |
|-------|-------|
| Test ID | {test-id} |
| Title | {test-title} |
| Package | {package} |
| Agent | {agent-name} |
| Executed | {timestamp} |
| Duration | {duration} |
| Filtered | {Yes: TC-001, TC-003 / No} |

## Results Summary

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-001 | {description} | Pass/Fail |
...

## Overall Status: {PASS/FAIL/PARTIAL}

{Include failed test details, environment info, observations}
EOF
```

#### 4.2 Write agent experience report (experience.r.md)

```bash
cat > "${REPORT_DIR}/experience.r.md" << 'EOF'
---
test-id: {test-id}
test-title: {test-title}
package: {package}
agent: {agent-name}
executed: {timestamp}
status: complete|partial|incomplete
---

# Agent Experience Report: {test-id}

## Summary
{Brief summary of execution experience and friction level}

## Friction Points

### Documentation Gaps
- {Any missing or unclear documentation}

### Tool Behavior Issues
- {Unexpected behavior, confusing errors}

### API/CLI Friction
- {Inconsistent flags, awkward workflows}

## Root Cause Analysis
{For failures: WHY not just WHAT}

## Improvement Suggestions
- [ ] {Actionable improvements}

## Workarounds Used
- {What required workarounds}

## Positive Observations
- {What worked well}
EOF
```

**Note:** If no friction was encountered, the AX report should note "No significant friction encountered" in the Summary section.

#### 4.3 Write metadata (metadata.yml)

```bash
cat > "${REPORT_DIR}/metadata.yml" << EOF
run-id: "${TIMESTAMP_ID}"
test-id: "{test-id}"
package: "{package}"
agent: "{agent-name}"
started: "{start-timestamp}"
completed: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
duration: "{duration-seconds}s"
status: "{status}"
results:
  passed: {count}
  failed: {count}
  total: {count}
failed_test_cases:
  - TC-NNN
test_cases:
  filtered: {true|false}
  executed: [{list of TC IDs}]
git:
  branch: "$(git symbolic-ref --short HEAD 2>/dev/null || echo 'detached-HEAD')"
  commit: "$(git rev-parse --short HEAD)"
tools:
  ruby: "$(ruby --version | cut -d' ' -f2)"
EOF
```

#### 4.4 Report file paths

After writing reports, include the paths in the response:

```
Reports written:
- ${REPORT_DIR}/summary.r.md
- ${REPORT_DIR}/experience.r.md
- ${REPORT_DIR}/metadata.yml
```

### 5. Return Summary

Summarize the test execution in the response. Reports have been persisted to disk in step 4.

```markdown
## E2E Test Execution Report

**Test ID:** {test-id}
**Package:** {package}
**Executed:** {timestamp}
**Agent:** {agent-name}

### Results

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-001    | ...         | Pass   |
| TC-002    | ...         | Fail   |

### Overall Status: {PASS/FAIL}

### Observations

{Any observations or issues noted during execution}

### Reports

Reports persisted to `.cache/ace-test-e2e/`:
- `{timestamp}-{short-pkg}-{short-id}/` - Sandbox with test artifacts
- `{timestamp}-{short-pkg}-{short-id}-reports/` - Reports folder containing:
  - `summary.r.md` - Detailed test results
  - `experience.r.md` - Friction points and improvement suggestions
  - `metadata.yml` - Run metadata
```

## Error Handling

### Test Case Failure

If a test case fails:
1. Record the failure details
2. Continue with remaining test cases
3. Include failure in summary report

### Environment Issues

If the sandbox is missing or corrupted:
1. Report the error immediately
2. Do NOT attempt to recreate the sandbox
3. Return an error summary

### Test Case Filter Failure

If you realize you executed test cases that should have been filtered:
1. **STOP** - Do not write reports with incorrect data
2. Note the error in your response
3. Offer to re-run with correct filtering
