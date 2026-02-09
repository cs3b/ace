---
test-id: MT-REVIEW-006
title: Multi-Dimensional Review Architecture (CLI)
area: review
package: ace-review
priority: high
duration: ~3min
automation-candidate: true
requires:
  tools: [ace-review, git]
  ruby: ">= 3.0"
  api-keys: [GOOGLE_API_KEY]
last-verified: null
verified-by: null
---

# Multi-Dimensional Review Architecture (CLI)

## Objective

Verify that ace-review's multi-dimensional review features (multi-model execution, reviewers format) work correctly through the CLI interface with real API calls.

## Prerequisites

- Ruby >= 3.0 installed
- ace-review CLI available
- API keys configured (GOOGLE_API_KEY, OPENAI_API_KEY)
- git installed

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="review"
SHORT_ID="mt006"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Initialize git repo
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$TEST_DIR"

echo "=== Environment Verification ==="
which ace-review && ace-review --version
ruby --version
echo "PROJECT_ROOT: $PROJECT_ROOT"
echo "TEST_DIR: $TEST_DIR"
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
# Create preset directories
mkdir -p .ace/review/presets

# Create minimal config
cat > .ace/review/config.yml << 'EOF'
defaults:
  model: "google:gemini-2.5-flash"
EOF

# Preset 1: Single model (minimal cost)
cat > .ace/review/presets/minimal.yml << 'EOF'
description: "Minimal E2E test preset"
model: google:gemini-2.5-flash
instructions:
  system: "You are a code reviewer. Be brief."
  user: "Review this code. List any issues in 1-2 sentences."
EOF

# Preset 2: Multi-model (2 cheap models)
cat > .ace/review/presets/multi-model.yml << 'EOF'
description: "Multi-model E2E test"
models:
  - google:gemini-2.5-flash
  - google:gemini-2.5-flash
instructions:
  system: "Brief code review."
  user: "List issues only."
EOF

# Preset 3: New reviewers format
cat > .ace/review/presets/reviewers-test.yml << 'EOF'
description: "Reviewers format E2E test"
reviewers:
  - name: "reviewer-1"
    model: "google:gemini-2.5-flash"
  - name: "reviewer-2"
    model: "google:gemini-2.5-flash"
instructions:
  system: "Brief review."
  user: "Review:"
EOF

# Create test file
cat > calculator.rb << 'EOF'
# Simple calculator for E2E testing
class Calculator
  def add(a, b)
    a + b
  end

  def subtract(a, b)
    a - b
  end
end
EOF

# Commit initial state
git add .
git commit -m "Initial commit" --quiet

# Make a small change for diff
cat >> calculator.rb << 'EOF'

  def multiply(a, b)
    a * b
  end
EOF

git add calculator.rb
git commit -m "Add multiply method" --quiet

echo "Test data created successfully"
SANDBOX
```

## Test Cases

### TC-001: Single Model Review via CLI

**Objective:** Verify basic ace-review execution with a single model.

**Steps:**
1. Run ace-review with minimal preset
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   SESSION_DIR="$PWD/session-tc001"

   OUTPUT=$(ace-review review \
     --preset minimal \
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

2. Verify results
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   SESSION_DIR="$PWD/session-tc001"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Exit code $EXIT_CODE"

   # Check session directory was created
   [ -d "$SESSION_DIR" ] && echo "PASS: Session directory created" || echo "FAIL: No session directory"

   # Check review file exists
   REVIEW_FILE=$(ls "$SESSION_DIR"/*.md 2>/dev/null | grep -v prompt | head -1)
   [ -n "$REVIEW_FILE" ] && echo "PASS: Review file created: $REVIEW_FILE" || echo "FAIL: No review file"

   # Check review has content
   if [ -n "$REVIEW_FILE" ]; then
     LINES=$(wc -l < "$REVIEW_FILE")
     [ "$LINES" -gt 5 ] && echo "PASS: Review has content ($LINES lines)" || echo "FAIL: Review too short"
   fi
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Session directory created
- Review markdown file created with content

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Multi-Model Execution

**Objective:** Verify ace-review can execute with multiple models.

**Steps:**
1. Run ace-review with multi-model preset
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   SESSION_DIR="$PWD/session-tc002"

   OUTPUT=$(ace-review review \
     --preset multi-model \
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

2. Verify results
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   SESSION_DIR="$PWD/session-tc002"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Exit code $EXIT_CODE"

   # Check session directory
   [ -d "$SESSION_DIR" ] && echo "PASS: Session directory created" || echo "FAIL: No session directory"

   # Check multiple review files (one per model)
   REVIEW_COUNT=$(ls "$SESSION_DIR"/*.md 2>/dev/null | grep -v prompt | wc -l | tr -d ' ')
   echo "Review files found: $REVIEW_COUNT"
   [ "$REVIEW_COUNT" -ge 1 ] && echo "PASS: Review file(s) created" || echo "FAIL: No review files"

   # List session contents
   echo "Session contents:"
   ls -la "$SESSION_DIR"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Multiple review files created (or single consolidated review)
- Session contains metadata

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Reviewers Format Preset

**Objective:** Verify the new reviewers format (Task 233) works via CLI.

**Steps:**
1. Run ace-review with reviewers-format preset
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   SESSION_DIR="$PWD/session-tc003"

   OUTPUT=$(ace-review review \
     --preset reviewers-test \
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

2. Verify results
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   SESSION_DIR="$PWD/session-tc003"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Exit code $EXIT_CODE"

   # Check session directory
   [ -d "$SESSION_DIR" ] && echo "PASS: Session directory created" || echo "FAIL: No session directory"

   # Check review file exists
   REVIEW_COUNT=$(ls "$SESSION_DIR"/*.md 2>/dev/null | grep -v prompt | wc -l | tr -d ' ')
   [ "$REVIEW_COUNT" -ge 1 ] && echo "PASS: Review file(s) created" || echo "FAIL: No review files"

   # Check metadata exists
   [ -f "$SESSION_DIR/metadata.yml" ] && echo "PASS: Metadata file created" || echo "INFO: No metadata file (may be normal)"

   # List session contents
   echo "Session contents:"
   ls -la "$SESSION_DIR"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Preset with reviewers format is parsed and executed
- Review output created

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Error Handling - Invalid Preset

**Objective:** Verify ace-review handles invalid preset gracefully.

**Steps:**
1. Run ace-review with nonexistent preset
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-review review \
     --preset nonexistent-preset-xyz \
     --subject "diff:HEAD~1" \
     --auto-execute 2>&1)
   EXIT_CODE=$?

   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   SANDBOX
   ```

2. Verify error handling
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit for invalid preset" || echo "FAIL: Expected non-zero exit"

   # Check for error message
   echo "$OUTPUT" | grep -qi "not found\|unknown\|error\|invalid" && \
     echo "PASS: Error message present" || \
     echo "FAIL: No clear error message"
   SANDBOX
   ```

**Expected:**
- Exit code: non-zero
- Error message indicates preset not found

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

- [ ] TC-001: Single model review executes successfully
- [ ] TC-002: Multi-model execution works
- [ ] TC-003: Reviewers format preset works
- [ ] TC-004: Invalid preset returns error

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Tests use real API calls to verify end-to-end functionality
- Cost is minimized by using:
  - `google:gemini-2.5-flash` (cheapest model)
  - Minimal prompts (no bundle, short system/user prompts)
  - Tiny diffs (~10 lines)
- Estimated cost per full test run: ~$0.001
- Strategy selection (full/chunked/adaptive) is internal and not verified directly
- Future enhancement: Add strategy metadata to session output for deeper E2E verification
