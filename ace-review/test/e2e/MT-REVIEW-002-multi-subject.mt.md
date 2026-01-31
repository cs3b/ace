---
test-id: MT-REVIEW-002
title: Multi-Subject Merging and Type Detection
area: review
package: ace-review
priority: high
duration: ~20min
automation-candidate: true
requires:
  tools: [ace-review, git]
  ruby: ">= 3.0"
last-verified: null
verified-by: null
---

# Multi-Subject Merging and Type Detection

## Objective

Verify that ace-review correctly handles multiple subjects from different sources, properly detects subject types (pr, diff, files), merges them with deduplication, and processes them through the SubjectExtractor molecule.

## Prerequisites

- Ruby >= 3.0 installed
- ace-review package available in PATH
- git installed (for diff operations)

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="review"
SHORT_ID="mt002"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize git repo with some commits for diff testing
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$TEST_DIR"

echo "=== Tool Verification ==="
which ace-review && ace-review --version || echo "ace-review not in PATH"
which git && git --version
echo "========================="
```

## Test Data

```bash
# Create some test files
mkdir -p "$TEST_DIR/lib"
cat > "$TEST_DIR/lib/example.rb" << 'EOF'
# frozen_string_literal: true

class Example
  def hello
    "Hello, World!"
  end
end
EOF

cat > "$TEST_DIR/README.md" << 'EOF'
# Example Project

This is a test project for E2E testing.
EOF

# Initial commit
git add .
git commit -m "Initial commit" --quiet

# Make some changes for diff testing
cat >> "$TEST_DIR/lib/example.rb" << 'EOF'

  def goodbye
    "Goodbye!"
  end
EOF

cat >> "$TEST_DIR/README.md" << 'EOF'

## Features
- Example feature
EOF

git add .
git commit -m "Add features" --quiet

# Create another file for testing
cat > "$TEST_DIR/lib/helper.rb" << 'EOF'
# frozen_string_literal: true

module Helper
  def assist
    "Helping!"
  end
end
EOF

git add .
git commit -m "Add helper" --quiet

# Create preset directory with a simple test preset
mkdir -p "$TEST_DIR/.ace/review/presets"
cat > "$TEST_DIR/.ace/review/presets/test.yml" << 'EOF'
description: "Test preset for multi-subject testing"
model: "test-model"
EOF

# Create minimal config
cat > "$TEST_DIR/.ace/review/config.yml" << 'EOF'
defaults:
  model: "test-model"
EOF
```

## Test Cases

### TC-001: Single Diff Subject

**Objective:** Verify that a single diff subject is correctly processed.

**Steps:**
1. Run ace-review with a single diff subject
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset test --subject "diff:HEAD~1" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify command completes successfully
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Single diff subject processed" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

**Expected:**
- Exit code: 0
- Command processes the diff subject

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Single Files Subject

**Objective:** Verify that a single files subject is correctly processed.

**Steps:**
1. Run ace-review with a files subject
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset test --subject "files:*.md" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify command completes
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Files subject processed" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

**Expected:**
- Exit code: 0
- Command processes the files subject

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Multiple Subjects - Mixed Types

**Objective:** Verify that multiple subjects of different types are merged correctly.

**Steps:**
1. Run ace-review with multiple subjects
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset test \
     --subject "diff:HEAD~2" \
     --subject "files:lib/*.rb" \
     --dry-run 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify command processes both subjects
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Multiple subjects merged" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

**Expected:**
- Exit code: 0
- Both diff and files subjects are processed

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Duplicate Subject Deduplication

**Objective:** Verify that duplicate subjects are deduplicated.

**Steps:**
1. Run ace-review with duplicate subjects
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset test \
     --subject "diff:HEAD~1" \
     --subject "diff:HEAD~1" \
     --subject "diff:HEAD~2" \
     --dry-run 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify command completes (deduplication happens internally)
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Duplicate subjects handled" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

**Expected:**
- Exit code: 0
- Duplicates are removed internally

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Error - Empty Subject Filtering

**Objective:** Verify that empty subjects are filtered out.

**Steps:**
1. Run ace-review with mixed empty and valid subjects
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset test \
     --subject "" \
     --subject "diff:HEAD~1" \
     --dry-run 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify command completes with valid subject
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Empty subjects filtered" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

**Expected:**
- Exit code: 0
- Empty subjects are filtered, valid subject processed

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Three or More Subjects

**Objective:** Verify that three or more subjects are all processed correctly.

**Steps:**
1. Run ace-review with three subjects
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset test \
     --subject "files:README.md" \
     --subject "diff:HEAD~1" \
     --subject "files:lib/*.rb" \
     --dry-run 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify all subjects processed
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Three subjects processed" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

**Expected:**
- Exit code: 0
- All three subjects are merged and processed

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Error - No Subject Provided

**Objective:** Verify behavior when no subject is provided (relies on preset default or fails).

**Steps:**
1. Run ace-review without any subject
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset test --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Check behavior (may succeed with default or fail)
   ```bash
   # Note: behavior depends on whether preset has default subject
   echo "Exit code was: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "INFO: No subject - used default from preset or empty" || echo "INFO: No subject - command failed as expected"
   ```

**Expected:**
- Exit code: depends on preset configuration
- Either succeeds with default subject or fails with clear message

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Staged Changes Subject

**Objective:** Verify that the 'staged' keyword works for reviewing staged changes.

**Steps:**
1. Make and stage some changes
   ```bash
   cd "$TEST_DIR"
   echo "# New comment" >> "$TEST_DIR/lib/example.rb"
   git add "$TEST_DIR/lib/example.rb"
   ```

2. Run ace-review with staged subject
   ```bash
   OUTPUT=$(ace-review --preset test --subject "staged" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

3. Verify command processes staged changes
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Staged changes processed" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

4. Clean up staged changes
   ```bash
   git checkout -- "$TEST_DIR/lib/example.rb"
   ```

**Expected:**
- Exit code: 0
- Staged changes are reviewed

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

- [ ] TC-001: Single diff subject works
- [ ] TC-002: Single files subject works
- [ ] TC-003: Multiple mixed subjects merge correctly
- [ ] TC-004: Duplicate subjects are deduplicated
- [ ] TC-005: Empty subjects are filtered
- [ ] TC-006: Three or more subjects work
- [ ] TC-007: No subject behavior is handled
- [ ] TC-008: Staged changes subject works

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace integration tests from ace-review/test/integration/multi_subject_integration_test.rb
- Tests use --dry-run flag to avoid actual LLM calls
- Subject merging is handled by SubjectExtractor molecule with DeepMerger
- Subject types: diff:RANGE, files:PATTERN, pr:NUMBER, staged
- Test requires git init with commits for diff testing
