---
test-id: MT-{AREA}-{NNN}
title: {Descriptive Title}
area: {area-name}
package: {package-name}
priority: high|medium|low
duration: ~{X}min
automation-candidate: true|false
requires:
  tools: [{tool1}, {tool2}]
  ruby: ">= 3.0"
last-verified: YYYY-MM-DD
verified-by: {agent-name}
---

# {Title}

## Objective

{What this test verifies - 1-2 sentences describing the purpose and scope}

## Prerequisites

- {Requirement 1 - e.g., Ruby >= 3.0 installed}
- {Requirement 2 - e.g., StandardRB gem available}

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-{package-name}-{test-id}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Use $PROJECT_ROOT/bin/ace-{tool} for project binaries
```

**Directory Structure:** See [e2e-testing.g.md](../guides/e2e-testing.g.md#directory-structure) for the full directory layout.

## Test Data

```bash
# Create test files in $TEST_DIR
cat > "$TEST_DIR/example.rb" << 'EOF'
# Example Ruby file for testing
class Example
  def hello
    puts "Hello, World!"
  end
end
EOF
```

<!-- For tests that create isolated git repos and use ace-taskflow/ace-git-worktree:

```bash
# Create isolated git repository within $TEST_DIR
REPO_DIR="$TEST_DIR/test-repo"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Create taskflow structure...
mkdir -p .ace-taskflow/v.test/tasks/001-feature
# ... create task files ...
git add .ace-taskflow/
git commit -m "Add taskflow structure" --quiet

# IMPORTANT: Set PROJECT_ROOT_PATH for isolated testing
# This ensures ace-* commands use the isolated repo, not the main project
export PROJECT_ROOT_PATH="$REPO_DIR"
```

See: e2e-testing.g.md § "Environment Isolation for Taskflow-Aware Tests"
-->

## Test Cases

### TC-001: {Test Case Name}

**Objective:** {What this specific test case verifies}

**Steps:**
1. {Step description}
   ```bash
   {command to execute}
   ```

**Expected:**
- Exit code: {expected exit code}
- Output contains: "{expected output substring}"
- {Additional expectations}

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: {Test Case Name}

**Objective:** {What this specific test case verifies}

**Steps:**
1. {Step description}
   ```bash
   {command to execute}
   ```

**Expected:**
- {Expected behavior}

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

<!-- ERROR / NEGATIVE TEST CASES (Required)

Every E2E test MUST include at least one error/negative test case. These catch
crashes, missing error handling, and wrong exit codes — bugs that happy-path-only
tests consistently miss.

Place error TCs BEFORE happy-path TCs when they test pre-condition failures
(e.g., missing config file, no active session). This ensures errors are caught
from clean state before any session/state is created.

Examples of error TCs to consider:
- Wrong arguments or positional vs flag mismatch
- Missing required files (config, input data)
- Command run without required prior state (no session, no login)
- Invalid input format (malformed YAML, wrong file type)
- Exit code verification (specific codes, not just non-zero)

### TC-0XX: Error — {Error Scenario Name}

**Objective:** Verify that {tool} handles {error condition} with a clear error
message and correct exit code.

**Steps:**
1. {Trigger the error condition}
   ```bash
   OUTPUT=$({command with wrong args} 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code and error message
   ```bash
   [ "$EXIT_CODE" -eq {expected_code} ] && echo "PASS: Correct exit code" || echo "FAIL: Expected {expected_code}, got $EXIT_CODE"
   echo "$OUTPUT" | grep -qi "{expected_text}" && echo "PASS: Error message correct" || echo "FAIL: Wrong error message"
   ```

**Expected:**
- Exit code: {specific exit code}
- Output contains: "{expected error message}"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

END OF ERROR TC TEMPLATE -->

## Cleanup

Cleanup is optional. The workflow controls this via `cleanup.enabled` setting (default: disabled).
Artifacts in `.cache/ace-test-e2e/` are gitignored, so keeping them doesn't affect the repository.

```bash
# Only run if cleanup is enabled - reports are preserved by default
# rm -rf "$TEST_DIR"
# rm -rf "${TEST_DIR}-reports"
```

## Success Criteria

- [ ] TC-001: {Summary criterion}
- [ ] TC-002: {Summary criterion}

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- {Any additional notes about this test scenario}
- {Known limitations or considerations}
- Structure TCs as a real user workflow — each TC should build on the state left by previous TCs
- Discover file paths at runtime from CLI output or directory scanning, not from assumptions
- Include negative assertions: verify that wrong/old paths do NOT exist
- See: e2e-testing.g.md § "Avoiding False Positive Tests" for anti-patterns and reviewer checklist
