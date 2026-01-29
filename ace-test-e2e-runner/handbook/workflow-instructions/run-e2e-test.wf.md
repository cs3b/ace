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

Run the commands in the "Environment Setup" section:

1. **Capture project root** (before changing directories):
   ```bash
   PROJECT_ROOT="$(pwd)"
   ```
2. Generate a test ID using `ace-timestamp encode`
3. Create the test directory structure:
   ```bash
   TEST_ID="$(ace-timestamp encode)"
   TEST_DIR="$PROJECT_ROOT/.cache/test-e2e/${TEST_ID}-{package}"
   mkdir -p "$TEST_DIR/artifacts"
   cd "$TEST_DIR/artifacts"
   ```
4. Set up any required environment variables
5. Navigate to the artifacts directory for test data creation

**Important:** Always capture `PROJECT_ROOT` before `cd` operations. Use `$PROJECT_ROOT/bin/ace-lint` for absolute paths to project binaries when executing from test directories.

**Directory Structure:**
```
.cache/test-e2e/{timestamp}-{package}/
├── test-report.md               # Test results (written at completion)
├── agent-experience-report.md   # AX report (written at completion)
├── metadata.yml                 # Run metadata (written at completion)
└── artifacts/                   # Test data files (created during setup)
    ├── valid.rb
    └── ...
```

**Directory Convention:**
- Package test: `.cache/test-e2e/{timestamp}-{package}/`
- Project test: `.cache/test-e2e/{timestamp}/`

Example: `.cache/test-e2e/8oig0h-ace-lint/`

### 5. Create Test Data

Execute the commands in the "Test Data" section to create necessary files in the `artifacts/` directory:

1. Create all test files as specified (inside `$TEST_DIR/artifacts/`)
2. Verify files were created correctly
3. Report file contents if needed for debugging

**Note:** Test data files go in `$TEST_DIR/artifacts/`, keeping them separate from reports which are written to `$TEST_DIR/`.

### 6. Execute Test Cases

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

After test execution completes (pass or fail), write three report files to `$TEST_DIR/`.

**Important:** Replace all `{placeholder}` values with actual data before writing. Do not copy placeholders literally - substitute them with real values from test execution.

**Error Handling:**
- If `$TEST_DIR` doesn't exist, create it with `mkdir -p "$TEST_DIR"`
- If write fails (permissions), report the error and suggest manual intervention
- For partial test completion, still write reports with status "partial" or "incomplete"

#### 7.1 Write test-report.md

```bash
cat > "$TEST_DIR/test-report.md" << 'EOF'
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

#### 7.2 Write agent-experience-report.md

```bash
cat > "$TEST_DIR/agent-experience-report.md" << 'EOF'
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

#### 7.3 Write metadata.yml

```bash
cat > "$TEST_DIR/metadata.yml" << EOF
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
Reports written to: $TEST_DIR/
- test-report.md
- agent-experience-report.md
- metadata.yml
```

### 8. Run Cleanup (Optional)

Cleanup is controlled by the `cleanup.enabled` setting in `.ace-defaults/e2e-runner/config.yml`.

**Default: disabled** - Artifacts and reports are preserved for debugging and analysis.

If cleanup is enabled, execute:

```bash
rm -rf "$TEST_DIR"
```

**Note:** Test directories in `.cache/test-e2e/` are gitignored, so keeping artifacts doesn't affect the repository. Old test directories can be removed manually with:

```bash
rm -rf .cache/test-e2e/*
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

Reports persisted to `{$TEST_DIR}/`:
- `test-report.md` - Detailed test results
- `agent-experience-report.md` - Friction points and improvement suggestions
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

Reports persisted to `{$TEST_DIR}/`:
- `test-report.md` - Detailed test results
- `agent-experience-report.md` - Friction points and improvement suggestions
- `metadata.yml` - Run metadata
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
