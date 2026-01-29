---
workflow-id: wfi-run-e2e-test
name: Run E2E Test
description: Execute an E2E test scenario with full agent guidance
version: "1.2"
source: ace-test-e2e-runner
---

# Run E2E Test Workflow

This workflow guides an agent through executing an E2E test scenario.

## Arguments

- `PACKAGE` (optional) - The package containing the test (e.g., `ace-lint`). If omitted, looks for `test/e2e/` in project root.
- `TEST_ID` (optional) - The test identifier (e.g., `MT-LINT-001`). If omitted, runs all tests.

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

1. Write all reports to `.cache/ace-test-e2e/` (steps 7.1-7.3)
2. Return only paths and summary counts
3. Orchestrator reads files for detailed aggregation

## Workflow Steps

### 1. Locate Test Scenario(s)

Determine the test directory based on arguments:

**No arguments** - Look in project root:
```bash
find test/e2e -name "*.mt.md" 2>/dev/null | sort
```

**PACKAGE only** - Find all tests in package:
```bash
find {PACKAGE}/test/e2e -name "*.mt.md" 2>/dev/null | sort
```

**PACKAGE and TEST_ID** - Find specific test:
```bash
find {PACKAGE}/test/e2e -name "*{TEST_ID}*.mt.md" 2>/dev/null | head -1
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

**How this section works:**
- The instructions below explain CONVENTIONS and PATTERNS for sandbox naming
- The test file's "Environment Setup" section contains the ACTUAL COMMANDS to execute
- You must run the test file's commands, then verify isolation in Section 4.1

Run the commands in the "Environment Setup" section of the test file:

1. **Capture project root** (before changing directories):
   ```bash
   PROJECT_ROOT="$(pwd)"
   ```
2. Generate a timestamp ID using `ace-timestamp encode`
3. **Derive short names** for the folder:
   ```bash
   # Strip "ace-" prefix from package name
   SHORT_PKG="${PACKAGE#ace-}"   # e.g., ace-git-commit → git-commit

   # Convert test ID to short format: MT-COMMIT-001 → mt001
   SHORT_ID=$(echo "{test-id}" | sed 's/MT-[A-Z]*-/mt/' | tr '[:upper:]' '[:lower:]')
   ```
4. Create the test directory structure:
   ```bash
   TIMESTAMP_ID="$(ace-timestamp encode)"
   TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
   mkdir -p "$TEST_DIR"
   cd "$TEST_DIR"
   ```
5. Set up any required environment variables
6. Navigate to the test directory for test data creation

**Important:** Always capture `PROJECT_ROOT` before `cd` operations. Use `$PROJECT_ROOT/bin/ace-lint` for absolute paths to project binaries when executing from test directories.

**Execution Order:**
1. Read the test file's "Environment Setup" section
2. Execute THOSE commands (not the examples in this workflow)
3. Proceed to Section 4.1 to verify sandbox isolation
4. Only continue to Section 5 after verification passes

**Workflow patterns vs. test file commands:**
- This workflow shows the PATTERN (naming conventions, structure)
- The test file's Environment Setup contains the COMMANDS to run
- The test file has `cd "$TEST_DIR"` - this MUST be executed

**Directory Structure & Naming Convention:**

Folder names use a shortened format for readability:
- `{timestamp}` - 6-char base36 timestamp (unchanged)
- `{short-pkg}` - package name with `ace-` prefix removed (e.g., `ace-lint` → `lint`)
- `{short-id}` - lowercase prefix + number only (e.g., `MT-LINT-001` → `mt001`)

```
.cache/ace-test-e2e/
├── 8osvnh-lint-mt001/              # Sandbox folder (shorter name)
│   ├── (git repo, test files, etc.)
│   └── ...
├── 8osvnh-lint-mt001-reports/      # Reports grouped in folder
│   ├── summary.r.md                # Test results
│   ├── experience.r.md             # AX report
│   └── metadata.yml                # Run metadata
└── 8osynv-final-report.md          # Suite report (only final at top level)
```

**Directory Convention:**
- Package test: `.cache/ace-test-e2e/{timestamp}-{short-pkg}-{short-id}/`
- Project test: `.cache/ace-test-e2e/{timestamp}-{short-id}/`

Example: `.cache/ace-test-e2e/8oig0h-lint-mt001/`

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
REMOTES=$(git remote -v 2>/dev/null)
if [ -z "$REMOTES" ]; then
  echo "PASS: No git remotes (isolated repo)"
else
  echo "FAIL: Git remotes found - NOT an isolated repo!"
  echo "  Remotes: $REMOTES"
  echo "  ACTION: STOP - You are in the main repository."
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

Execute the commands in the "Test Data" section to create necessary test files:

1. Create all test files as specified (inside `$TEST_DIR/`)
2. Verify files were created correctly
3. Report file contents if needed for debugging

**Note:** Test data files go in `$TEST_DIR/`, while reports are written as sibling files outside the sandbox folder.

### 6. Execute Test Cases

> **Reminder**: All test commands execute inside `$TEST_DIR`. If unsure, run `pwd` and verify `.cache/ace-test-e2e/` in path.

For each test case (TC-NNN):

1. **Read the objective** - Understand what this test verifies
2. **Execute the steps** - Run each command in sequence
3. **Capture results** - Record:
   - Actual exit code
   - Command output
   - Any error messages
4. **Compare to expected** - Check against expected results
5. **Record status** - Pass or Fail

Report each test case result immediately after execution.

**During execution, track friction points** for the Agent Experience Report:
- Documentation gaps discovered
- Unexpected tool behavior
- Confusing error messages
- Workarounds needed
- Positive observations

### 7. Write Reports to Disk

After test execution completes (pass or fail), write three report files to a `-reports/` folder alongside the sandbox folder.

**Important:** Replace all `{placeholder}` values with actual data before writing. Do not copy placeholders literally - substitute them with real values from test execution.

**Create reports directory first:**
```bash
REPORTS_DIR="${TEST_DIR}-reports"
mkdir -p "$REPORTS_DIR"
```

**Error Handling:**
- If the cache directory doesn't exist, create it with `mkdir -p "$(dirname "$TEST_DIR")"`
- If write fails (permissions), report the error and suggest manual intervention
- For partial test completion, still write reports with status "partial" or "incomplete"

#### 7.1 Write summary report (summary.r.md)

```bash
cat > "${REPORTS_DIR}/summary.r.md" << 'EOF'
---
test-id: {test-id}
package: {package}
agent: {agent-name}
executed: {timestamp}
status: pass|fail|partial|incomplete
passed: {count}
failed: {count}
total: {count}
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

## Results Summary

| Test Case | Description | Status |
|-----------|-------------|--------|
| TC-001 | {description} | Pass/Fail |
...

## Overall Status: {PASS/FAIL/PARTIAL}

{Include failed test details, environment info, observations}
EOF
```

#### 7.2 Write agent experience report (experience.r.md)

```bash
cat > "${REPORTS_DIR}/experience.r.md" << 'EOF'
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
cat > "${REPORTS_DIR}/metadata.yml" << EOF
run-id: "${TEST_ID}"
test-id: "{test-id}"
package: "{package}"
agent: "{agent-name}"
started: "{start-timestamp}"
completed: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
duration: "{duration-seconds}s"
status: "{pass|fail|partial}"
results:
  passed: {count}
  failed: {count}
  total: {count}
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
Reports written to: ${REPORTS_DIR}/
- summary.r.md
- experience.r.md
- metadata.yml
```

### 7.5 Write Suite Final Report (Multi-Test Runs Only)

When running multiple tests (e.g., all tests in a package), generate a suite-level final report after all tests complete.

**Trigger:** Only when multiple test scenarios were executed in steps 2-7.

**Suite Report Path:**
```bash
SUITE_ID="$(ace-timestamp encode)"  # Generate once at start of suite run
SUITE_REPORT="$PROJECT_ROOT/.cache/ace-test-e2e/${SUITE_ID}-final-report.md"
```

**Content:**
```bash
cat > "$SUITE_REPORT" << 'EOF'
---
suite-id: {suite-id}
package: {package}
agent: {agent-name}
executed: {timestamp}
tests-run: {count}
status: pass|fail|partial
---

# E2E Test Suite Report

**Package:** {package}
**Tests Run:** {count}
**Executed:** {timestamp}
**Agent:** {agent-name}

## Summary

| Test ID | Title | Status | Passed | Failed |
|---------|-------|--------|--------|--------|
| MT-XXX-001 | {title} | Pass/Fail | {n} | {n} |
| MT-XXX-002 | {title} | Pass/Fail | {n} | {n} |
...

**Overall:** {total-passed}/{total-cases} test cases passed ({percentage}%)

## Test Details

### MT-XXX-001: {title} ({passed}/{total} passed)
- TC-001: {description} - Pass/Fail
- TC-002: {description} - Pass/Fail
...

### MT-XXX-002: {title} ({passed}/{total} passed)
...

## Reports

Reports persisted to `.cache/ace-test-e2e/`:
- {timestamp}-{short-pkg}-mtxxx001/ - sandbox
- {timestamp}-{short-pkg}-mtxxx001-reports/summary.r.md
- {timestamp}-{short-pkg}-mtxxx001-reports/experience.r.md
- {timestamp}-{short-pkg}-mtxxx001-reports/metadata.yml
...
EOF
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
| MT-LINT-001 | Ruby Validator Fallback | Pass |
| MT-LINT-002 | ... | Fail |

### Overall: {passed}/{total} passed

### Failed Tests

{Details of any failed tests}

### Reports

Reports persisted to `.cache/ace-test-e2e/`:
- `{suite-timestamp}-final-report.md` - Suite summary report (only final at top level)
- `{timestamp}-{short-pkg}-mtxxx001/` - Sandbox
- `{timestamp}-{short-pkg}-mtxxx001-reports/` - Reports folder
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

## Example Invocations

**Run a specific test in a package:**
```
/ace:run-e2e-test ace-lint MT-LINT-001
```

This would:
1. Find `ace-lint/test/e2e/MT-LINT-001-*.mt.md`
2. Execute the test scenario
3. Report results

**Run all tests in a package:**
```
/ace:run-e2e-test ace-lint
```

This would:
1. Find all `ace-lint/test/e2e/*.mt.md` files
2. Execute each test scenario sequentially
3. Report combined results

**Run all tests in project root:**
```
/ace:run-e2e-test
```

This would:
1. Find all `test/e2e/*.mt.md` files in project root
2. Execute each test scenario sequentially
3. Report combined results
