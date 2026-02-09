---
test-id: MT-REVIEW-005
title: Multi-Model Executor
area: review
package: ace-review
priority: high
duration: ~3min
automation-candidate: true
requires:
  tools: [ace-review, git]
  ruby: ">= 3.0"
  api-keys: [GOOGLE_API_KEY]
last-verified: 2026-02-08
verified-by: claude-opus-4-6
---

# Multi-Model Executor

## Objective

Verify that ace-review's multi-model executor correctly handles single and multiple model execution, output file generation, and error handling with real API calls.

## Prerequisites

- Ruby >= 3.0 installed
- ace-review CLI available in PATH
- API keys configured (GOOGLE_API_KEY)
- git installed

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="review"
SHORT_ID="mt005"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Initialize git repo (needed for project root detection)
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$TEST_DIR"

echo "=== Tool Verification ==="
which ace-review && ace-review --version || echo "ace-review not in PATH"
echo "========================="

# === SANDBOX ISOLATION CHECKPOINT ===
echo "=== SANDBOX ISOLATION CHECK ==="
CURRENT_DIR="$(pwd)"
if [[ "$CURRENT_DIR" == *".cache/ace-test-e2e/"* ]]; then
  echo "PASS: Working directory is inside sandbox"
else
  echo "FAIL: NOT in sandbox! Current: $CURRENT_DIR"
  exit 1
fi
if git rev-parse --git-dir >/dev/null 2>&1; then
  REMOTES=$(git remote -v 2>/dev/null)
  if [ -z "$REMOTES" ]; then
    echo "PASS: No git remotes (isolated repo)"
  else
    echo "FAIL: Git remotes found - NOT isolated!"
    exit 1
  fi
else
  echo "PASS: No git repo in sandbox (tools use PROJECT_ROOT_PATH)"
fi
if [ -f "CLAUDE.md" ] || [ -f "Gemfile" ] || [ -d ".ace-taskflow" ]; then
  echo "FAIL: Main project markers found!"
  exit 1
else
  echo "PASS: No main project markers"
fi
echo "=== ISOLATION VERIFIED ==="
```

## Test Data

```bash
ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
# Create preset directory
mkdir -p .ace/review/presets

# Minimal config
cat > .ace/review/config.yml << 'EOF'
defaults:
  model: "google:gemini-2.5-flash"
EOF

# Single model preset (minimal cost)
cat > .ace/review/presets/single.yml << 'EOF'
description: "Single model E2E test"
model: google:gemini-2.5-flash
instructions:
  system: "Brief code review."
  user: "List issues in 1-2 sentences."
EOF

# Multi-model preset (2 cheap models)
cat > .ace/review/presets/multi.yml << 'EOF'
description: "Multi-model E2E test"
models:
  - google:gemini-2.5-flash
  - google:gemini-2.5-flash
instructions:
  system: "Brief code review."
  user: "List issues only."
EOF

# Test file
cat > sample.rb << 'EOF'
# Sample Ruby file for review testing
class Calculator
  def add(a, b)
    a + b
  end
end
EOF

# Commit initial state
git add .
git commit -m "Initial commit" --quiet

# Make a change for diff
cat >> sample.rb << 'EOF'

  def multiply(a, b)
    a * b
  end
EOF

git add sample.rb
git commit -m "Add multiply" --quiet

echo "Test data created successfully"
SANDBOX
```

## Test Cases

### TC-001: Single Model Execution

**Objective:** Verify that ace-review executes with a single model and produces output.

**Steps:**
1. Run ace-review with single model preset
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   SESSION_DIR="$PWD/session-tc001"

   OUTPUT=$(ace-review review \
     --preset single \
     --subject "diff:HEAD~1" \
     --session-dir "$SESSION_DIR" \
     --auto-execute \
     --quiet 2>&1)
   EXIT_CODE=$?

   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   SANDBOX
   ```

2. Verify execution
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   SESSION_DIR="$PWD/session-tc001"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Exit code $EXIT_CODE"

   # Check session directory
   [ -d "$SESSION_DIR" ] && echo "PASS: Session directory created" || echo "FAIL: No session directory"

   # Check review file exists and has content
   REVIEW_FILE=$(ls "$SESSION_DIR"/*.md 2>/dev/null | grep -v prompt | head -1)
   if [ -n "$REVIEW_FILE" ]; then
     echo "PASS: Review file created: $(basename $REVIEW_FILE)"
     LINES=$(wc -l < "$REVIEW_FILE")
     [ "$LINES" -gt 3 ] && echo "PASS: Review has content ($LINES lines)" || echo "FAIL: Review too short"
   else
     echo "FAIL: No review file"
   fi
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Session directory created
- Review file with actual content

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Multi-Model Execution

**Objective:** Verify that ace-review can execute with multiple models.

**Steps:**
1. Run ace-review with multi-model preset
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   SESSION_DIR="$PWD/session-tc002"

   OUTPUT=$(ace-review review \
     --preset multi \
     --subject "diff:HEAD~1" \
     --session-dir "$SESSION_DIR" \
     --auto-execute \
     --quiet 2>&1)
   EXIT_CODE=$?

   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   SANDBOX
   ```

2. Verify multi-model execution
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   SESSION_DIR="$PWD/session-tc002"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Exit code $EXIT_CODE"

   # Check session directory
   [ -d "$SESSION_DIR" ] && echo "PASS: Session directory created" || echo "FAIL: No session directory"

   # Check for review output (may be multiple files or consolidated)
   REVIEW_COUNT=$(ls "$SESSION_DIR"/*.md 2>/dev/null | grep -v prompt | wc -l | tr -d ' ')
   echo "Review files: $REVIEW_COUNT"
   [ "$REVIEW_COUNT" -ge 1 ] && echo "PASS: Review file(s) created" || echo "FAIL: No review files"

   # Check for metadata
   [ -f "$SESSION_DIR/metadata.yml" ] && echo "PASS: Metadata file created" || echo "INFO: No metadata file"

   # List contents
   echo "Session contents:"
   ls -la "$SESSION_DIR"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Review output created for multi-model execution
- Session contains output files

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Execution Timing

**Objective:** Verify execution completes within reasonable time bounds.

**Steps:**
1. Measure execution time
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   SESSION_DIR="$PWD/session-tc003"

   START_TIME=$(date +%s)
   OUTPUT=$(ace-review review \
     --preset single \
     --subject "diff:HEAD~1" \
     --session-dir "$SESSION_DIR" \
     --auto-execute \
     --quiet 2>&1)
   EXIT_CODE=$?
   END_TIME=$(date +%s)
   DURATION=$((END_TIME - START_TIME))

   echo "Exit code: $EXIT_CODE"
   echo "Duration: ${DURATION}s"
   SANDBOX
   ```

2. Verify timing
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Execution succeeded" || echo "FAIL: Execution failed"

   # Should complete within 60 seconds (generous for API latency)
   [ "$DURATION" -lt 60 ] && echo "PASS: Completed in ${DURATION}s (< 60s)" || echo "FAIL: Took too long: ${DURATION}s"

   # Should take at least 1 second (real API call)
   [ "$DURATION" -ge 1 ] && echo "PASS: Duration indicates real execution" || echo "INFO: Very fast execution"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Completes within 60 seconds
- Takes > 1 second (indicates real API call)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Error Handling - Invalid Model

**Objective:** Verify graceful handling of invalid model configuration.

**Steps:**
1. Create preset with invalid model
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   # Create preset with invalid model name
   cat > .ace/review/presets/invalid-model.yml << 'EOF'
description: "Invalid model test"
model: nonexistent:fake-model-xyz
instructions:
  system: "Test"
  user: "Test"
EOF
   SANDBOX
   ```

2. Run ace-review with invalid model
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-review review \
     --preset invalid-model \
     --subject "diff:HEAD~1" \
     --auto-execute 2>&1)
   EXIT_CODE=$?

   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   SANDBOX
   ```

3. Verify error handling
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   # Should fail (non-zero exit)
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit for invalid model" || echo "FAIL: Expected non-zero exit"

   # Should have error message
   echo "$OUTPUT" | grep -qi "error\|invalid\|failed\|not found\|unknown" && \
     echo "PASS: Error message present" || \
     echo "INFO: Error format may vary"
   SANDBOX
   ```

**Expected:**
- Exit code: non-zero
- Error message indicates model issue

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

- [ ] TC-001: Single model execution produces review output
- [ ] TC-002: Multi-model execution works
- [ ] TC-003: Execution completes within reasonable time
- [ ] TC-004: Invalid model is handled gracefully

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Tests use real API calls with cheap models (google:gemini-2.5-flash)
- Cost control: minimal prompts, tiny diff (~10 lines)
- Estimated cost per full test run: ~$0.001
- Multi-model test uses same model twice to test execution path without extra API costs
- Previous version used --dry-run which couldn't verify actual execution
