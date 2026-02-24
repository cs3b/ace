---
workflow-id: wfi-run-e2e-test
name: e2e/run
description: Execute an E2E test scenario with full agent guidance
version: "1.6"
source: ace-test-runner-e2e
---

# Run E2E Test Workflow

This workflow guides an agent through executing an E2E test scenario.

## Arguments

- `PACKAGE` (optional) - The package containing the test (e.g., `ace-lint`). If omitted, looks for `test/e2e/` in project root.
- `TEST_ID` (optional) - The test identifier (e.g., `TS-LINT-001`). If omitted, runs all tests.
- `RUN_ID` (optional) - Pre-generated timestamp ID for deterministic report paths. Passed via `--run-id ID`. When provided, use this instead of generating a new timestamp.
- `TEST_CASES` (optional) - Comma-separated list of test case IDs to execute (e.g., `TC-001,tc-003,002`). When provided, only the specified test cases are executed; all others are skipped. IDs are normalized to `TC-NNN` format automatically.
- `REPORT_DIR` (optional) - Explicit report directory path. Passed via `--report-dir PATH`. When provided, use this path directly instead of computing `${TEST_DIR}-reports` from timestamp/package/test-id.

  **Accepted formats:**
  - `TC-001` - already normalized
  - `tc-001` - uppercased to `TC-001`
  - `001` - prefix added: `TC-001`
  - `1` - zero-padded and prefixed: `TC-001`
  - `TC-1` - zero-padded: `TC-001`

  When omitted, all test cases in the scenario are executed (default behavior).

## Command Context (Important)

- `/ace-e2e-run ...` is a chat slash command and must be invoked in agent chat, not in bash.
- Never run `/ace:...` as a shell command.
- If slash commands are unavailable in the environment, stop and report that limitation in the final `Issues` field.

## Canonical Conventions

- `ace-test-e2e` runs single-package scenarios; `ace-test-e2e-suite` runs suite-level execution
- Scenario IDs use `TS-<PACKAGE_SHORT>-<NNN>[-slug]`
- Standalone test cases use `TC-*.runner.md` and `TC-*.verify.md`
- TC artifacts are written under `results/tc/{NN}/`
- Summary counters use `tcs-passed`, `tcs-failed`, `tcs-total`, and `failed[].tc`

## Subagent Mode

When invoked as a subagent (via Task tool from `/ace-e2e-runs` orchestrator), this workflow operates with special considerations:

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

1. Write all reports to `.cache/ace-test-e2e/` (steps 7.1-7.3)
2. Return only paths and summary counts
3. Orchestrator reads files for detailed aggregation

## TC-Level Execution Mode

When invoked with `--tc-mode`, this workflow operates in TC-level mode where the sandbox is pre-populated by `SetupExecutor` and only a single test case is executed. Steps 1-5 of the standard workflow are skipped entirely.

### TC-Level Arguments

- `PACKAGE` (required) - Package name (e.g., `ace-lint`)
- `TEST_ID` (required) - Parent scenario ID (e.g., `TS-LINT-001`)
- `TC_ID` (required) - Test case ID (e.g., `TC-001`)
- `--tc-mode` (required) - Activates TC-level execution mode
- `--sandbox SANDBOX_PATH` (required) - Path to pre-populated sandbox directory
- `--run-id RUN_ID` (optional) - Pre-generated timestamp ID for report paths
- `--env KEY=VALUE,...` (optional) - Environment variables to export (comma-separated)

### TC-Level Execution Steps

1. **Verify sandbox** — Confirm `SANDBOX_PATH` exists and contains the expected test environment
2. **Enter sandbox** — `cd SANDBOX_PATH`
3. **Export environment variables** — If `--env` was provided, export each key-value pair: `export KEY=VALUE`
4. **Execute TC steps** — Follow the test case instructions (objective, steps, expected results)
5. **Write per-TC reports** — Generate `summary.r.md`, `experience.r.md`, `metadata.yml` in `{RUN_ID}-{pkg}-{scenario}-{tc}-reports/`
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
- **Always export environment variables from `--env` before executing test steps**
- Execute only the steps described in the test case content
- Report actual results even if they differ from expected

---

## Workflow Steps

### 1. Locate Test Scenario(s)

Determine the test directory based on arguments:

**No arguments** - Look in project root:
```bash
find test/e2e -name "scenario.yml" -path "*/TS-*" 2>/dev/null | sort
```

**PACKAGE only** - Find all tests in package:
```bash
find {PACKAGE}/test/e2e -name "scenario.yml" -path "*/TS-*" 2>/dev/null | sort
```

**PACKAGE and TEST_ID** - Find specific test:
```bash
find {PACKAGE}/test/e2e -path "*{TEST_ID}*/scenario.yml" 2>/dev/null | head -1
```

If no tests found, report error and exit.

### 2. Read Test Scenario

**For each test scenario file found**, read it completely. Parse the frontmatter to extract:

- `test-id` - The test identifier
- `title` - Test title
- `priority` - Test priority level
- `duration` - Expected duration
- `requires` - Required tools and versions

**When running multiple tests:** Execute steps 2-7 for each scenario sequentially, then generate a combined summary report.

### 2.5. Parse and Filter Test Cases

If the `TEST_CASES` argument was provided, parse and validate it before proceeding.

**Step 1: Parse TEST_CASES argument**

Split the comma-separated list into individual IDs:

```bash
# Parse comma-separated test case IDs
IFS=',' read -ra RAW_CASES <<< "$TEST_CASES"
```

**Step 2: Normalize test case IDs**

Each ID must be normalized to the canonical `TC-NNN` format (uppercase, zero-padded to 3 digits):

```bash
normalize_tc_id() {
  local id="$1"
  # Remove leading/trailing whitespace
  id="$(echo "$id" | xargs)"
  # Uppercase
  id="$(echo "$id" | tr '[:lower:]' '[:upper:]')"
  # Extract numeric portion
  local num
  if [[ "$id" =~ ^TC-([0-9]+)$ ]]; then
    num="${BASH_REMATCH[1]}"
  elif [[ "$id" =~ ^([0-9]+)$ ]]; then
    num="${BASH_REMATCH[1]}"
  else
    echo "ERROR: Invalid test case ID format: '$1' (expected TC-NNN, NNN, or N)" >&2
    return 1
  fi
  # Zero-pad to 3 digits
  printf "TC-%03d" "$((10#$num))"
}

# Normalize all IDs and deduplicate
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

**Step 3: Validate test cases exist in the test file**

Verify that each requested test case has a matching `### TC-NNN:` header in the test scenario file:

```bash
# Extract available test cases from the test file
AVAILABLE_CASES=($(grep -oE '^### TC-[0-9]+:' "$TEST_FILE" | grep -oE 'TC-[0-9]+'))

# Validate each requested case exists
INVALID_CASES=()
for tc in "${FILTERED_CASES[@]}"; do
  if ! printf '%s\n' "${AVAILABLE_CASES[@]}" | grep -qx "$tc"; then
    INVALID_CASES+=("$tc")
  fi
done

if [[ ${#INVALID_CASES[@]} -gt 0 ]]; then
  echo "ERROR: Test case(s) not found: ${INVALID_CASES[*]}"
  echo "Available test cases in $TEST_FILE:"
  for available in "${AVAILABLE_CASES[@]}"; do
    echo "  - $available"
  done
  exit 1
fi

echo "Validated ${#FILTERED_CASES[@]} test case(s): ${FILTERED_CASES[*]}"
```

**When TEST_CASES is empty or not provided:** Skip this section entirely and execute all test cases (default behavior). The `FILTERED_CASES` array will not be set, which signals "run all" in step 6.

### 3. Verify Prerequisites

Check that all prerequisites are met:

1. **Required tools**: Verify each tool listed in `requires.tools` is available
2. **Ruby version**: Check `ruby --version` meets requirement
3. **Package dependencies**: Ensure package is installed

Report any missing prerequisites before proceeding.

### 4. Execute Environment Setup

> **CRITICAL: SANDBOX REQUIRED**
>
> All E2E tests MUST run in an isolated sandbox under `.cache/ace-test-e2e/`.
> NEVER execute test commands in the main repository. The test file's "Environment Setup"
> section creates this sandbox - you MUST execute it and verify isolation BEFORE proceeding.

**Authoritative Reference:** Read `wfi://e2e/setup-sandbox` for the complete sandbox setup pattern including the Standard Setup Script section.

**Execution Order:**
1. Read the test file's "Environment Setup" section
2. Execute the test file's commands (they follow the `wfi://e2e/setup-sandbox` pattern)
3. Proceed to Section 4.1 to verify sandbox isolation
4. Only continue to Section 5 after verification passes

**Expected Variables After Setup:**
- `PROJECT_ROOT` - Original project directory (for accessing binaries like `$PROJECT_ROOT/bin/ace-lint`)
- `TEST_DIR` - Sandbox directory (current working directory after setup)
- `REPORTS_DIR` - Reports directory for test outputs
- `TIMESTAMP_ID` - Unique identifier for this test run

**Pre-generated Run ID:** If `RUN_ID` was provided as an argument (via `--run-id`), set `TIMESTAMP_ID=$RUN_ID` instead of calling `ace-b36ts encode`. This ensures the orchestrator knows the exact report path.

**Directory Structure & Naming Convention:**

Folder names use a shortened format for readability:
- `{timestamp}` - 6-char base36 timestamp (unchanged)
- `{short-pkg}` - package name with `ace-` prefix removed (e.g., `ace-lint` → `lint`)
- `{short-id}` - lowercase prefix + number only (e.g., `TS-LINT-001` → `ts001`)

```
.cache/ace-test-e2e/
├── 8osvnh-lint-ts001/                      # Sandbox folder
│   ├── (test artifacts)
│   └── ...
├── 8osvnh-lint-ts001-reports/              # Reports subfolder
│   ├── summary.r.md
│   ├── experience.r.md
│   └── metadata.yml
└── 8osynv-final-report.md                  # Suite report (sibling)
```

**Directory Convention:**
- Package test: `.cache/ace-test-e2e/{timestamp}-{short-pkg}-{short-id}/`
- Project test: `.cache/ace-test-e2e/{timestamp}-{short-id}/`

Example: `.cache/ace-test-e2e/8oig0h-lint-ts001/`

### 4.1 Sandbox Isolation Checkpoint (MANDATORY)

> **STOP - Verify Before Continuing**
>
> Before proceeding to Test Data or Test Cases, you MUST verify sandbox isolation.
> Failure to verify will result in polluting the main repository with test artifacts.

**Run these verification commands:**

```bash
echo "=== SANDBOX ISOLATION CHECK ==="

# Check 1: Current directory must be under .cache/ace-test-e2e/
CURRENT_DIR="$(pwd)"
if [[ "$CURRENT_DIR" == *".cache/ace-test-e2e/"* ]]; then
  echo "PASS: Working directory is inside sandbox"
  echo "  Location: $CURRENT_DIR"
else
  echo "FAIL: NOT in sandbox!"
  echo "  Current: $CURRENT_DIR"
  echo "  Expected: Should contain '.cache/ace-test-e2e/'"
  echo "  ACTION: STOP - Do not proceed. Re-run Environment Setup."
fi

# Check 2: Git remote must be empty (fresh isolated repo)
if git rev-parse --git-dir >/dev/null 2>&1; then
  REMOTES=$(git remote -v 2>/dev/null)
  if [ -z "$REMOTES" ]; then
    echo "PASS: No git remotes (isolated repo)"
  else
    echo "FAIL: Git remotes found - NOT an isolated repo!"
    echo "  Remotes: $REMOTES"
    echo "  ACTION: STOP - You are in the main repository."
  fi
else
  echo "PASS: No git repo in sandbox (tools use PROJECT_ROOT_PATH)"
fi

# Check 3: Project root markers should NOT exist
if [ -f "CLAUDE.md" ] || [ -f "Gemfile" ] || [ -d ".ace-taskflow" ]; then
  echo "FAIL: Main project markers found - NOT an isolated repo!"
  echo "  ACTION: STOP - You are in the main repository."
else
  echo "PASS: No main project markers (expected for sandbox)"
fi

echo "=== END ISOLATION CHECK ==="
```

**Interpretation:**
- **All checks PASS**: Continue to Section 5 (Create Test Data)
- **Any check FAILS**:
  1. STOP immediately - do NOT execute any test commands
  2. Return to project root: `cd "$PROJECT_ROOT"`
  3. Re-read and re-execute the test file's Environment Setup
  4. Re-run this checkpoint until all checks pass

### 5. Create Test Data

> **Prerequisite**: Section 4.1 (Sandbox Isolation Checkpoint) must PASS before proceeding.

> **CRITICAL: Use `ace-test-e2e-sh` for ALL commands after Environment Setup**
>
> Every bash command from "Test Data" and "Test Cases" sections MUST be executed
> through the sandbox wrapper. This ensures proper working directory and isolation
> regardless of shell state between invocations.
>
> **Single command:** `ace-test-e2e-sh "$TEST_DIR" git add README.md`
> **Multi-command block:** Pass via stdin:
> ```
> ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
> cat > file.txt << 'EOF'
> content
> EOF
> git add file.txt
> SANDBOX
> ```

**Pre-Creation Sandbox Verification (MANDATORY):**

Before creating ANY test files, run this verification gate:

```bash
echo "=== PRE-CREATION SANDBOX VERIFICATION ==="
if [[ "$(pwd)" != *".cache/ace-test-e2e/"* ]]; then
  echo "FATAL: Not in sandbox. Refusing to create files."
  echo "  Current: $(pwd)"
  echo "  ACTION: Re-run Environment Setup and isolation checkpoint"
  exit 1
fi
echo "OK: Confirmed in sandbox - safe to create test data"
```

**Why this matters:** If the `cd "$TEST_DIR"` command in Environment Setup failed silently, this gate prevents polluting the main repository with test fixtures.

Execute the commands in the "Test Data" section to create necessary test files:

1. Create all test files as specified (inside `$TEST_DIR/`)
2. Verify files were created correctly
3. Report file contents if needed for debugging

**Note:** Test data files go in `$TEST_DIR/`, while reports are written to a reports subfolder (`${TEST_DIR}-reports/`).

### 5.5. Test Case Filter Verification (MANDATORY when TEST_CASES provided)

> **STOP - Verify Filter Before Executing**
>
> When TEST_CASES argument was provided, you MUST verify the filter before executing any test cases.
> Failure to verify will result in executing unintended test cases.

**Run this verification when FILTERED_CASES is set:**

```bash
if [ -n "${FILTERED_CASES+x}" ]; then
  echo "=== TEST CASE FILTER VERIFICATION ==="
  echo "Filter active. Will execute ONLY: ${FILTERED_CASES[*]}"
  echo "Total test cases to execute: ${#FILTERED_CASES[@]}"
  echo "All other test cases will be SKIPPED"
  echo "=== END FILTER VERIFICATION ==="
fi
```

**Interpretation:**
- If this checkpoint prints test cases, you MUST skip all test cases NOT in the list
- For each test case in the test file, check: "Is this TC-ID in FILTERED_CASES?"
- If NO → Skip entirely, log "Skipping TC-NNN (not in filter)"
- If YES → Execute normally

### 6. Execute Test Cases

> **CRITICAL: Use `ace-test-e2e-sh` for ALL test case commands**
>
> Each bash block runs in a fresh shell. Use `ace-test-e2e-sh "$TEST_DIR"` to ensure
> every command executes inside the sandbox. See Section 5 for syntax examples.

**Determine execution scope:**

- If `FILTERED_CASES` is set (from step 2.5), execute **only** test cases whose IDs are in the `FILTERED_CASES` array. Skip all other test cases.
- If `FILTERED_CASES` is not set, execute **all** test cases in the scenario (default behavior).

**Example: Filtering in action**

If `FILTERED_CASES=(TC-002)` and the test file has TC-001, TC-002, TC-003:

```
TC-001: Check filter → "TC-001" not in ["TC-002"] → SKIP, log "Skipping TC-001 (not in filter)"
TC-002: Check filter → "TC-002" in ["TC-002"] → EXECUTE
TC-003: Check filter → "TC-003" not in ["TC-002"] → SKIP, log "Skipping TC-003 (not in filter)"
```

**Result**: Only TC-002 executes, report shows 1 test case total.

For each test case (TC-NNN), execute the standalone runner/verifier flow:
1. Execute runner goals and save artifacts to `results/tc/{NN}/`
2. Verify artifacts using paired `.verify.md`
3. Record per-goal verdict with evidence

For each test case (TC-NNN):

1. **Check filter** - If `FILTERED_CASES` is set and this test case ID is not in the array, **skip** this test case entirely (do not execute any of its steps). Log: `Skipping TC-NNN (not in filter)`.
2. **Read the objective** - Understand what this test verifies
3. **Execute runner/verifier flow** - run goals, then validate evidence
4. **Capture results** - Record:
   - Actual exit code
   - Command output
   - Any error messages
5. **Evaluate evidence** - verifier expectations and artifacts
6. **Record status** - Pass or Fail

Report each test case result immediately after execution.

**During execution, track friction points** for the Agent Experience Report:
- Documentation gaps discovered
- Unexpected tool behavior
- Confusing error messages
- Workarounds needed
- Positive observations

### 7. Write Reports to Disk

After test execution completes (pass or fail), write three report files to a reports subfolder.

**Important:** Replace all `{placeholder}` values with actual data before writing. Do not copy placeholders literally - substitute them with real values from test execution.

**Set up report paths (reports subfolder):**
```bash
# If --report-dir was provided as argument, use it directly:
if [ -n "$PROVIDED_REPORT_DIR" ]; then
  REPORT_DIR="$PROVIDED_REPORT_DIR"
else
  # Otherwise compute from sandbox path:
  REPORT_DIR="${TEST_DIR}-reports"  # e.g., .cache/ace-test-e2e/8osvnh-lint-ts001-reports
fi
mkdir -p "$REPORT_DIR"
# Report files: ${REPORT_DIR}/summary.r.md, ${REPORT_DIR}/experience.r.md, ${REPORT_DIR}/metadata.yml
```

**Error Handling:**
- If the cache directory doesn't exist, create it with `mkdir -p "$(dirname "$TEST_DIR")"`
- If write fails (permissions), report the error and suggest manual intervention
- For partial test completion, still write reports with status "partial" or "incomplete"

#### 7.1 Write summary report (summary.r.md)

**Note:** When test case filtering is active (`FILTERED_CASES` is set), include **only** the executed test cases in the Results Summary table. Do not include skipped test cases. Add a "Filtered" note in the Test Information section indicating which test cases were selected.

```bash
cat > "${REPORT_DIR}/summary.r.md" << 'EOF'
---
test-id: {test-id}
package: {package}
agent: {agent-name}
executed: {timestamp}
status: {status}  # One of: pass, fail, partial, incomplete
passed: [{list of passed TC IDs or goal IDs}]
failed: [{list of failed TC IDs or goal IDs}]
score: "{passed-count}/{total-count}"
verdict: pass|fail|partial|incomplete
total: {count}
filtered: {true|false}  # Whether test case filtering was applied
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

### Goal Evaluation

| Goal/Criterion | Status | Evidence |
|----------------|--------|----------|
| {criterion-1} | PASS/FAIL | {artifact/output reference} |
| {criterion-2} | PASS/FAIL | {artifact/output reference} |
EOF
```

#### 7.2 Write agent experience report (experience.r.md)

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

#### 7.3 Write metadata (metadata.yml)

```bash
cat > "${REPORT_DIR}/metadata.yml" << EOF
run-id: "${TIMESTAMP_ID}"
test-id: "{test-id}"
package: "{package}"
agent: "{agent-name}"
started: "{start-timestamp}"
completed: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
duration: "{duration-seconds}s"
status: "{status}"  # One of: pass, fail, partial, incomplete
results:
  passed: {count}
  failed: {count}
  total: {count}
failed_test_cases:       # List of TC IDs that failed (empty array if all passed)
  - TC-NNN               # e.g., - TC-002
test_cases:
  filtered: {true|false}           # Whether filtering was applied
  executed: [{list of TC IDs}]     # e.g., [TC-001, TC-003] or [all]
git:
  branch: "$(git symbolic-ref --short HEAD 2>/dev/null || echo 'detached-HEAD')"
  commit: "$(git rev-parse --short HEAD)"
tools:
  ruby: "$(ruby --version | cut -d' ' -f2)"
EOF
```

#### 7.4 Report file paths

After writing reports, include the paths in the response:

```
Reports written:
- ${REPORT_DIR}/summary.r.md
- ${REPORT_DIR}/experience.r.md
- ${REPORT_DIR}/metadata.yml
```

### 8. Run Cleanup (Optional)

Cleanup is controlled by the `cleanup.enabled` setting in `.ace-defaults/e2e-runner/config.yml`.

**Default: disabled** - Artifacts and reports are preserved for debugging and analysis.

If cleanup is enabled, execute:

```bash
rm -rf "$TEST_DIR"
rm -rf "${TEST_DIR}-reports"
```

**Note:** Test directories in `.cache/ace-test-e2e/` are gitignored, so keeping artifacts doesn't affect the repository. Old test directories can be removed manually with:

```bash
rm -rf .cache/ace-test-e2e/*
```

### 9. Generate Summary Report

Summarize the test execution in the response. Reports have been persisted to disk in step 7.

**Single test:**
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

**Multiple tests (package-wide):**
```markdown
## E2E Test Suite Report

**Package:** {package}
**Tests Run:** {count}
**Executed:** {timestamp}
**Agent:** {agent-name}

### Summary

| Test ID | Title | Status |
|---------|-------|--------|
| TS-LINT-001 | Ruby Validator Fallback | Pass |
| TS-LINT-002 | ... | Fail |

### Overall: {passed}/{total} passed

### Failed Tests

{Details of any failed tests}

### Reports

Reports persisted to `.cache/ace-test-e2e/`:
- `{suite-timestamp}-final-report.md` - Suite summary report (only final at top level)
- `{timestamp}-{short-pkg}-ts001/` - Sandbox
- `{timestamp}-{short-pkg}-ts001-reports/` - Reports folder
  - `summary.r.md`
  - `experience.r.md`
  - `metadata.yml`
...
```

### 10. Update Test Scenario (if needed)

If all tests pass, update the test scenario frontmatter:

```yaml
last-verified: {today's date}
verified-by: claude-{model}
```

## Error Handling

### Prerequisite Failure

If prerequisites are not met:
1. Report which prerequisites failed
2. Provide instructions to resolve
3. Do not proceed with test execution

### Test Case Failure

If a test case fails:
1. Record the failure details
2. Continue with remaining test cases
3. Include failure in summary report

### Environment Issues

If environment setup fails:
1. Report the error
2. Attempt cleanup
3. Suggest troubleshooting steps

### Sandbox Isolation Failure

If the sandbox isolation checkpoint fails:
1. **STOP all test execution immediately**
2. Do NOT proceed with test data or test cases
3. Return to `$PROJECT_ROOT` and diagnose:
   - Did you execute the test file's Environment Setup?
   - Did `mkdir` and `cd` commands succeed?
4. Re-execute Environment Setup from the test file
5. Re-run the isolation checkpoint
6. Only proceed when all checks pass

**Warning signs of wrong directory:**
- `pwd` shows main project path (no `.cache/ace-test-e2e/`)
- `git remote -v` shows remotes
- Files like `CLAUDE.md`, `Gemfile`, `.ace-taskflow/` exist

### Test Case Filter Failure

If you realize you executed test cases that should have been filtered:
1. **STOP** - Do not write reports with incorrect data
2. Note the error in your response
3. Offer to re-run with correct filtering

## Example Invocations

**Run a specific test in a package:**
```
/ace-e2e-run ace-lint TS-LINT-001
```

This would:
1. Find `ace-lint/test/e2e/TS-LINT-001-*/scenario.yml`
2. Execute the test scenario (reads TC files from the scenario directory)
3. Report results

**Run a single test case within a test scenario:**
```
/ace-e2e-run ace-lint TS-LINT-003 TC-002
```

This would:
1. Find `ace-lint/test/e2e/TS-LINT-003-*/scenario.yml`
2. Parse and normalize `TC-002`
3. Execute only TC-002, skipping all other test cases
4. Report results for TC-002 only

**Run multiple specific test cases:**
```
/ace-e2e-run ace-lint TS-LINT-001 TC-001,tc-003,002
```

This would:
1. Find `ace-lint/test/e2e/TS-LINT-001-*/scenario.yml`
2. Normalize IDs: `TC-001`, `tc-003` -> `TC-003`, `002` -> `TC-002`
3. Validate all three exist in the test file
4. Execute only TC-001, TC-002, TC-003 (skipping others)
5. Report filtered results

**Run all tests in a package:**
```
/ace-e2e-run ace-lint
```

This would:
1. Find all `ace-lint/test/e2e/TS-*/scenario.yml` directories
2. Execute each test scenario sequentially
3. Report combined results

**Run all tests in project root:**
```
/ace-e2e-run
```

This would:
1. Find all `test/e2e/TS-*/scenario.yml` directories in project root
2. Execute each test scenario sequentially
3. Report combined results
