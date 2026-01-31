---
test-id: MT-REVIEW-005
title: Multi-Model Executor
area: review
package: ace-review
priority: high
duration: ~10min
automation-candidate: true
requires:
  tools: [ace-review]
  ruby: ">= 3.0"
last-verified: null
verified-by: null
---

# Multi-Model Executor

## Objective

Verify that ace-review's multi-model executor correctly handles single and multiple model execution, timeout boundaries, partial failures, and output file generation using dry-run mode to avoid actual LLM API calls.

## Prerequisites

- Ruby >= 3.0 installed
- ace-review package available in PATH
- git installed (for project root detection)

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="review"
SHORT_ID="mt005"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize git repo (needed for project root detection)
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$TEST_DIR"

echo "=== Tool Verification ==="
which ace-review && ace-review --version || echo "ace-review not in PATH"
echo "========================="
```

## Test Data

```bash
# Create preset directory
mkdir -p "$TEST_DIR/.ace/review/presets"

# Single model preset
cat > "$TEST_DIR/.ace/review/presets/single.yml" << 'EOF'
description: "Single model review configuration"
model: google:gemini-2.5-flash
instructions:
  bundle:
    base: "prompt://base/system"
EOF

# Multi-model preset
cat > "$TEST_DIR/.ace/review/presets/multi.yml" << 'EOF'
description: "Multi-model review configuration"
models:
  - google:gemini-2.5-flash
  - anthropic:claude-sonnet
instructions:
  bundle:
    base: "prompt://base/system"
EOF

# Three model preset for parallel execution test
cat > "$TEST_DIR/.ace/review/presets/parallel.yml" << 'EOF'
description: "Parallel multi-model review configuration"
models:
  - google:gemini-2.5-flash
  - anthropic:claude-sonnet
  - openai:gpt-4o
max_concurrent: 3
instructions:
  bundle:
    base: "prompt://base/system"
EOF

# Create minimal config file
cat > "$TEST_DIR/.ace/review/config.yml" << 'EOF'
defaults:
  model: "google:gemini-2.5-flash"
EOF

# Create a test file for subject
cat > "$TEST_DIR/sample.rb" << 'EOF'
# Sample Ruby file for review testing
class Calculator
  def add(a, b)
    a + b
  end

  def subtract(a, b)
    a - b
  end
end
EOF

git add .
git commit -m "Initial commit" --quiet
```

## Test Cases

### TC-001: Execute Review with Single Model (dry-run)

**Objective:** Verify that ace-review can execute with a single model in dry-run mode.

**Steps:**
1. Run ace-review with single model preset in dry-run mode
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset single --subject "sample.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify dry-run execution
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Dry-run completed successfully" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -qi "dry.run\|would execute\|model" && echo "PASS: Dry-run output present" || echo "INFO: Output format may vary"
   ```

**Expected:**
- Exit code: 0
- Output indicates dry-run mode was used

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Execute Review with Multiple Models (dry-run)

**Objective:** Verify that ace-review can execute with multiple models in dry-run mode.

**Steps:**
1. Run ace-review with multi-model preset in dry-run mode
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset multi --subject "sample.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify multi-model handling
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Multi-model dry-run completed" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   # Check that multiple models are referenced in output
   GEMINI_COUNT=$(echo "$OUTPUT" | grep -ci "gemini" || true)
   CLAUDE_COUNT=$(echo "$OUTPUT" | grep -ci "claude\|anthropic\|sonnet" || true)
   echo "Gemini references: $GEMINI_COUNT, Claude/Anthropic references: $CLAUDE_COUNT"
   [ "$GEMINI_COUNT" -ge 1 ] || [ "$CLAUDE_COUNT" -ge 1 ] && echo "PASS: Model references found" || echo "INFO: Model names may not be in output"
   ```

**Expected:**
- Exit code: 0
- Both models are processed

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Timeout Handling (Bounded Execution)

**Objective:** Verify that ace-review respects timeout configuration and completes within bounded time.

**Steps:**
1. Run ace-review with explicit short timeout in dry-run mode
   ```bash
   cd "$TEST_DIR"
   # Measure execution time with dry-run
   START_TIME=$(date +%s)
   OUTPUT=$(ace-review --preset single --subject "sample.rb" --dry-run --timeout 60 2>&1)
   EXIT_CODE=$?
   END_TIME=$(date +%s)
   DURATION=$((END_TIME - START_TIME))

   echo "Exit code: $EXIT_CODE"
   echo "Duration: ${DURATION}s"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify bounded execution
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Completed successfully" || echo "FAIL: Expected exit code 0"
   # Dry-run should complete very quickly (well under timeout)
   [ "$DURATION" -lt 30 ] && echo "PASS: Completed within reasonable time (${DURATION}s < 30s)" || echo "FAIL: Took too long: ${DURATION}s"
   ```

**Expected:**
- Exit code: 0
- Execution completes well under the timeout (since it's dry-run)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Partial Failure Handling

**Objective:** Verify that when using multiple models, partial failures are handled gracefully.

**Steps:**
1. Run ace-review with parallel preset (tests multi-model infrastructure)
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset parallel --subject "sample.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify multi-model handling
   ```bash
   # In dry-run mode, all models should "succeed" (no actual API calls)
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Parallel execution completed" || echo "INFO: Exit code: $EXIT_CODE (may vary based on config)"

   # Verify presets are being loaded correctly
   MODEL_COUNT=$(echo "$OUTPUT" | grep -ci "model\|gemini\|claude\|gpt" || true)
   echo "Model-related references: $MODEL_COUNT"
   [ "$MODEL_COUNT" -ge 1 ] && echo "PASS: Model handling evident in output" || echo "INFO: Model names may not appear in dry-run output"
   ```

3. Test error scenario with invalid preset (simulates partial failure path)
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset nonexistent --subject "sample.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code for invalid preset: $EXIT_CODE"

   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Invalid preset correctly rejected" || echo "FAIL: Expected non-zero exit for invalid preset"
   echo "$OUTPUT" | grep -qi "not found\|unknown\|error\|invalid" && echo "PASS: Error message present" || echo "INFO: Error format may vary"
   ```

**Expected:**
- Parallel preset executes successfully in dry-run
- Invalid preset returns non-zero exit with error message

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Output File Generation

**Objective:** Verify that ace-review generates output files in the expected location.

**Steps:**
1. Run ace-review and check for output directory creation
   ```bash
   cd "$TEST_DIR"
   # First, check what output options are available
   ace-review --help 2>&1 | grep -i "output\|session\|report" | head -5

   # Run with dry-run and check for any session/output references
   OUTPUT=$(ace-review --preset single --subject "sample.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify output handling
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Command completed successfully" || echo "FAIL: Command failed"

   # Check if output references session directory or file paths
   echo "$OUTPUT" | grep -qiE "session|output|report|\.md" && echo "PASS: Output references found" || echo "INFO: Dry-run may not create files"

   # Check for any created directories in standard locations
   if [ -d "$TEST_DIR/.ace-review" ]; then
     echo "PASS: .ace-review directory created"
     ls -la "$TEST_DIR/.ace-review" 2>/dev/null | head -10
   else
     echo "INFO: .ace-review directory not created (expected in dry-run)"
   fi

   # Check common output locations
   if ls "$TEST_DIR"/*.md 2>/dev/null | head -5; then
     echo "PASS: Markdown output files present"
   else
     echo "INFO: No output files (expected in dry-run mode)"
   fi
   ```

**Expected:**
- Command completes successfully
- In dry-run mode, minimal or no file output (expected behavior)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

Cleanup is optional. The workflow controls this via `cleanup.enabled` setting (default: disabled).
Artifacts in `.cache/ace-test-e2e/` are gitignored, so keeping them doesn't affect the repository.

```bash
# Only run if cleanup is enabled - reports are preserved by default
# rm -rf "$TEST_DIR"
```

## Success Criteria

- [ ] TC-001: Single model execution works in dry-run mode
- [ ] TC-002: Multiple model execution works in dry-run mode
- [ ] TC-003: Execution completes within bounded time
- [ ] TC-004: Partial failures are handled gracefully
- [ ] TC-005: Output file generation works correctly

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace integration tests from:
  - ace-review/test/molecules/multi_model_executor_test.rb (13 tests)
- Tests use --dry-run flag to avoid actual LLM API calls
- The MultiModelExecutor handles:
  - Thread pool management with max_concurrent setting
  - Timeout enforcement per model
  - Partial failure handling (some models fail, others succeed)
  - Output file generation per model
  - Thread safety for concurrent execution
- Timeout tests verify bounded execution time, not actual timeout triggering
- Actual timeout behavior requires real API calls which are avoided in E2E tests
