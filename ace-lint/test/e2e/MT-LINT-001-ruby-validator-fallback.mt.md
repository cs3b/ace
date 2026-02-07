---
test-id: MT-LINT-001
title: Ruby Validator Fallback Behavior
area: lint
package: ace-lint
priority: high
duration: ~15min
automation-candidate: false
requires:
  tools: [standardrb, rubocop]
  ruby: ">= 3.0"
last-verified: 2026-02-07
verified-by: claude-opus-4.6
---

# Ruby Validator Fallback Behavior

## Objective

Verify that ace-lint correctly uses StandardRB as primary Ruby linter and falls back to RuboCop when StandardRB is unavailable. Test includes validator selection, auto-fix, and batch processing.

## Prerequisites

- Ruby >= 3.0 installed
- StandardRB gem installed (`gem install standardrb`)
- RuboCop gem installed (`gem install rubocop`)
- ace-lint package available in PATH

## Environment Setup

```bash
TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="lint"
SHORT_ID="mt001"
TEST_DIR=".cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Verify tools are available
echo "=== Tool Verification ==="
which ruby && ruby --version
which standardrb && standardrb --version
which rubocop && rubocop --version
echo "========================="
```

## Test Data

```bash
# Valid Ruby file (passes all linters)
cat > "$TEST_DIR/valid.rb" << 'EOF'
# frozen_string_literal: true

class Greeter
  def greet(name)
    "Hello, #{name}!"
  end
end
EOF

# Ruby file with style issues (fixable)
cat > "$TEST_DIR/style_issues.rb" << 'EOF'
class BadStyle
  def method_with_issues( arg1,arg2 )
    if arg1 == true
      puts "yes"
    else
      puts "no"
    end
  end
end
EOF

# Ruby file with syntax error
cat > "$TEST_DIR/syntax_error.rb" << 'EOF'
class Broken
  def unclosed
    puts "missing end"
EOF

# Create multiple files for batch testing
mkdir -p "$TEST_DIR/batch"
cat > "$TEST_DIR/batch/file1.rb" << 'EOF'
# frozen_string_literal: true

def file_one
  "one"
end
EOF

cat > "$TEST_DIR/batch/file2.rb" << 'EOF'
def file_two()
  "two"
end
EOF

cat > "$TEST_DIR/batch/file3.rb" << 'EOF'
# frozen_string_literal: true

class FileThree
  def run = "three"
end
EOF
```

## Test Cases

### TC-001: StandardRB Available - Valid File

**Objective:** Verify that valid Ruby code passes linting when StandardRB is available.

**Steps:**
1. Lint the valid file
   ```bash
   ace-lint lint "$TEST_DIR/valid.rb"
   ```

**Expected:**
- Exit code: 0
- Output indicates no issues found
- StandardRB was used (check output or logs)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: StandardRB Available - Fix Mode Detects and Fixes Style Issues

**Objective:** Verify that StandardRB detects and fixes style issues in `--fix` mode.

**Steps:**
1. Create a copy of the style issues file
   ```bash
   cp "$TEST_DIR/style_issues.rb" "$TEST_DIR/style_issues_copy.rb"
   ```

2. Run lint with --fix on the copy
   ```bash
   ace-lint lint --fix "$TEST_DIR/style_issues_copy.rb"
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

3. Verify the file was modified by comparing to original
   ```bash
   diff "$TEST_DIR/style_issues.rb" "$TEST_DIR/style_issues_copy.rb"
   ```

**Expected:**
- Exit code: 0 (fix mode auto-corrects and succeeds)
- diff shows differences between original and copy (style fixes applied)
- StandardRB was used (check output or logs)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: RuboCop Fallback (StandardRB Unavailable)

**Objective:** Verify that ace-lint falls back to RuboCop when StandardRB is not available.

**Steps:**
1. Temporarily hide StandardRB from PATH
   ```bash
   ORIGINAL_PATH="$PATH"
   # Create a temporary bin directory without standardrb
   mkdir -p "$TEST_DIR/fake_bin"
   for tool in ruby rubocop ace-lint; do
     ln -sf "$(which $tool)" "$TEST_DIR/fake_bin/"
   done
   export PATH="$TEST_DIR/fake_bin:$PATH"

   # Verify standardrb is not available
   which standardrb 2>/dev/null && echo "ERROR: standardrb still found" || echo "OK: standardrb not in PATH"
   ```

2. Run linting (should fall back to RuboCop)
   ```bash
   ace-lint lint "$TEST_DIR/valid.rb" 2>&1
   ```

3. Restore PATH
   ```bash
   export PATH="$ORIGINAL_PATH"
   ```

**Expected:**
- RuboCop is used instead of StandardRB
- Output or logs indicate fallback behavior
- Linting still produces results

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

**Note:** PATH manipulation may not work with mise shims because shims resolve executables through their own layer, bypassing PATH modifications.

**Recommended alternative for mise environments:**
```bash
# Find and temporarily rename the actual standardrb binary
STANDARDRB_PATH="$(mise which standardrb)"
mv "$STANDARDRB_PATH" "${STANDARDRB_PATH}.disabled"

# Run test...

# Restore after test
mv "${STANDARDRB_PATH}.disabled" "$STANDARDRB_PATH"
```

---

### TC-004: Auto-fix Functionality

**Objective:** Verify that ace-lint can auto-fix style issues.

**Steps:**
1. Create a copy of the style issues file
   ```bash
   cp "$TEST_DIR/style_issues.rb" "$TEST_DIR/style_issues_copy.rb"
   ```

2. Run linting with auto-fix
   ```bash
   ace-lint lint --fix "$TEST_DIR/style_issues_copy.rb"
   ```

3. Verify file was modified
   ```bash
   diff "$TEST_DIR/style_issues.rb" "$TEST_DIR/style_issues_copy.rb"
   ```

4. Re-lint the fixed file
   ```bash
   ace-lint lint "$TEST_DIR/style_issues_copy.rb"
   ```

**Expected:**
- File is modified after --fix
- Re-linting shows fewer or no issues
- Original file unchanged

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Batch Linting

**Objective:** Verify that ace-lint can process multiple files in a directory.

**Steps:**
1. Lint all files in batch directory
   ```bash
   ace-lint lint "$TEST_DIR/batch/"*.rb
   ```

**Expected:**
- All three files are processed
- Results shown for each file
- Summary of total issues

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
rm -rf "$TEST_DIR"
echo "Cleanup complete"
```

## Success Criteria

- [ ] TC-001: Valid Ruby file passes linting with StandardRB
- [ ] TC-002: Fix mode detects and fixes style issues
- [ ] TC-003: RuboCop fallback works when StandardRB unavailable
- [ ] TC-004: Auto-fix modifies files and reduces issues
- [ ] TC-005: Batch linting processes all files

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- This test requires both StandardRB and RuboCop to be installed
- TC-003 manipulates PATH which may affect other tests if not cleaned up properly
- Auto-fix may produce different results depending on tool versions
