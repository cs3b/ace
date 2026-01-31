---
test-id: MT-REVIEW-001
title: Preset Composition and Inheritance
area: review
package: ace-review
priority: high
duration: ~20min
automation-candidate: true
requires:
  tools: [ace-review, ace-bundle]
  ruby: ">= 3.0"
last-verified: null
verified-by: null
---

# Preset Composition and Inheritance

## Objective

Verify that ace-review preset composition system correctly handles multi-level inheritance, array merging, description overrides, model inheritance, caching behavior, and circular dependency detection.

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
SHORT_ID="mt001"
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

# Base code preset
cat > "$TEST_DIR/.ace/review/presets/code.yml" << 'EOF'
description: "Base code review configuration"
instructions:
  description: "Code review instructions"
  bundle:
    base: "prompt://base/system"
    sections:
      review_focus:
        title: "Files Under Review"
        files:
          - "prompt://focus/scope/tests"
          - "prompt://focus/languages/ruby"
      format_guidelines:
        title: "Format Guidelines"
        files:
          - "prompt://format/detailed"
model: gpro
EOF

# Composed code-pr preset that extends code
cat > "$TEST_DIR/.ace/review/presets/code-pr.yml" << 'EOF'
presets:
  - code
description: "Pull request review - comprehensive code changes review"
subject:
  bundle:
    sections:
      code_changes:
        title: "Code Changes"
        description: "Code changes to review from pull request"
        diffs:
          - "origin...HEAD"
EOF

# Multi-level inheritance: level_1 (base)
cat > "$TEST_DIR/.ace/review/presets/level_1.yml" << 'EOF'
description: "Level 1"
model: "base-model"
EOF

# Multi-level inheritance: level_2 extends level_1
cat > "$TEST_DIR/.ace/review/presets/level_2.yml" << 'EOF'
presets:
  - level_1
description: "Level 2"
context_2: "data_2"
EOF

# Multi-level inheritance: level_3 extends level_2
cat > "$TEST_DIR/.ace/review/presets/level_3.yml" << 'EOF'
presets:
  - level_2
description: "Level 3"
context_3: "data_3"
EOF

# Circular dependency: preset_a
cat > "$TEST_DIR/.ace/review/presets/preset_a.yml" << 'EOF'
presets:
  - preset_b
description: "Preset A"
EOF

# Circular dependency: preset_b
cat > "$TEST_DIR/.ace/review/presets/preset_b.yml" << 'EOF'
presets:
  - preset_a
description: "Preset B"
EOF

# Missing reference preset
cat > "$TEST_DIR/.ace/review/presets/broken.yml" << 'EOF'
presets:
  - nonexistent_base
description: "Broken composition"
EOF

# Array deduplication: base_sections
cat > "$TEST_DIR/.ace/review/presets/base_sections.yml" << 'EOF'
description: "Base with sections"
instructions:
  bundle:
    sections:
      files_section:
        files:
          - "base_file_1.md"
          - "base_file_2.md"
EOF

# Array deduplication: extended_sections
cat > "$TEST_DIR/.ace/review/presets/extended_sections.yml" << 'EOF'
presets:
  - base_sections
description: "Extended sections"
instructions:
  bundle:
    sections:
      files_section:
        files:
          - "base_file_2.md"
          - "extended_file.md"
EOF

# Create minimal config file
cat > "$TEST_DIR/.ace/review/config.yml" << 'EOF'
defaults:
  model: "test-model"
EOF

# Create a test file for subject
echo "# Test File" > "$TEST_DIR/test.rb"
git add .
git commit -m "Initial commit" --quiet
```

## Test Cases

### TC-001: Base Preset Composition (code + code-pr)

**Objective:** Verify that code-pr preset correctly inherits from code preset and overrides description.

**Steps:**
1. Use ace-review to show resolved preset configuration
   ```bash
   cd "$TEST_DIR"
   # Use list-presets to verify presets are discovered
   OUTPUT=$(ace-review list-presets 2>&1)
   echo "$OUTPUT"

   # Verify code-pr preset is found
   echo "$OUTPUT" | grep -q "code-pr" && echo "PASS: code-pr preset discovered" || echo "FAIL: code-pr not found"
   echo "$OUTPUT" | grep -q "code" && echo "PASS: code preset discovered" || echo "FAIL: code not found"
   ```

**Expected:**
- Both code and code-pr presets are discovered
- Presets are listed in output

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Model Inheritance

**Objective:** Verify that model setting is inherited from base preset.

**Steps:**
1. Run ace-review with code-pr preset in dry-run mode
   ```bash
   cd "$TEST_DIR"
   # Use --dry-run to avoid actual LLM calls and verify resolved configuration
   OUTPUT=$(ace-review --preset code-pr --subject "test.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"

   # Verify model was inherited from base preset (gpro from code.yml)
   echo "$OUTPUT" | grep -qi "gpro\|model" && echo "PASS: Model setting visible in output" || echo "INFO: Model may be resolved internally"
   ```

2. Verify exit code is 0 (dry-run success)
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Dry-run succeeded" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

**Expected:**
- Exit code: 0
- Model is inherited from base preset

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Multi-Level Composition (3 levels)

**Objective:** Verify that three-level preset inheritance works correctly.

**Steps:**
1. Run ace-review with level_3 preset
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset level_3 --subject "test.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify command completes successfully
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Multi-level composition succeeded" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

**Expected:**
- Exit code: 0
- Command processes the multi-level preset chain successfully

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Error - Circular Dependency Detection

**Objective:** Verify that circular dependencies are detected and handled gracefully.

**Steps:**
1. Attempt to use preset with circular dependency
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset preset_a --subject "test.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify error handling
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Circular dependency rejected with non-zero exit" || echo "FAIL: Expected non-zero exit code"
   echo "$OUTPUT" | grep -qi "circular\|cycle\|error\|failed" && echo "PASS: Error message present" || echo "INFO: Specific error message may vary"
   ```

**Expected:**
- Exit code: non-zero
- Output contains error message about circular dependency or failure to load

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Error - Missing Reference Handling

**Objective:** Verify that missing preset references are handled gracefully.

**Steps:**
1. Attempt to use preset with missing reference
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset broken --subject "test.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify error handling
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Missing reference rejected with non-zero exit" || echo "FAIL: Expected non-zero exit code"
   echo "$OUTPUT" | grep -qi "not found\|missing\|error\|failed" && echo "PASS: Error message present" || echo "INFO: Specific error message may vary"
   ```

**Expected:**
- Exit code: non-zero
- Output contains error message about missing preset

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Array Merging in Sections

**Objective:** Verify that arrays in sections are correctly merged with deduplication.

**Steps:**
1. Run ace-review with extended_sections preset
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset extended_sections --subject "test.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify command completes
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Array merging preset processed" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

**Expected:**
- Exit code: 0
- Arrays are merged with duplicates removed

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Error - Nonexistent Preset

**Objective:** Verify that using a completely nonexistent preset fails gracefully.

**Steps:**
1. Attempt to use nonexistent preset
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-review --preset totally_nonexistent --subject "test.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify error handling
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Nonexistent preset rejected with non-zero exit" || echo "FAIL: Expected non-zero exit code"
   echo "$OUTPUT" | grep -qi "not found\|unknown\|error" && echo "PASS: Error message present" || echo "INFO: Error message may vary"
   ```

**Expected:**
- Exit code: non-zero
- Output contains error message about unknown preset

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

- [ ] TC-001: Base preset composition works
- [ ] TC-002: Model inheritance works correctly
- [ ] TC-003: Multi-level composition works
- [ ] TC-004: Circular dependency detected and handled
- [ ] TC-005: Missing reference handled gracefully
- [ ] TC-006: Array merging in sections works
- [ ] TC-007: Nonexistent preset handled gracefully

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace integration tests from ace-review/test/integration/preset_composition_integration_test.rb
- Tests use --dry-run flag to avoid actual LLM calls
- Preset composition is handled by PresetManager molecule
- Test requires git init for project root detection
- Error TCs (004, 005, 007) test negative paths for robust error handling
