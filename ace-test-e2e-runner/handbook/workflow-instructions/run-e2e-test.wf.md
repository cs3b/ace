---
workflow-id: wfi-run-e2e-test
name: Run E2E Test
description: Execute an E2E test scenario with full agent guidance
version: "1.1"
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
3. Create the test directory in `.cache/test-e2e/{test-id}-{package}/`
4. Set up any required environment variables
5. Navigate to the test directory

**Important:** Always capture `PROJECT_ROOT` before `cd` operations. Use `$PROJECT_ROOT/bin/ace-lint` for absolute paths to project binaries when executing from test directories.

**Directory Convention:**
- Package test: `.cache/test-e2e/{timestamp}-{package}/`
- Project test: `.cache/test-e2e/{timestamp}/`

Example: `.cache/test-e2e/8oig0h-ace-lint/`

### 5. Create Test Data

Execute the commands in the "Test Data" section to create necessary files:

1. Create all test files as specified
2. Verify files were created correctly
3. Report file contents if needed for debugging

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

### 7. Run Cleanup (Optional)

Cleanup is controlled by the `cleanup.enabled` setting in `.ace-defaults/e2e-runner/config.yml`.

**Default: disabled** - Artifacts are preserved for debugging.

If cleanup is enabled, execute:

```bash
rm -rf "$TEST_DIR"
```

**Note:** Test directories in `.cache/test-e2e/` are gitignored, so keeping artifacts doesn't affect the repository. Old test directories can be removed manually with:

```bash
rm -rf .cache/test-e2e/*
```

### 8. Generate Summary Report

Summarize the test execution:

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
```

### 9. Update Test Scenario (if needed)

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
