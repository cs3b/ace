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
last-verified: 2026-02-08
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
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="lint"
SHORT_ID="mt001"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Set PROJECT_ROOT_PATH for sandbox isolation
export PROJECT_ROOT_PATH="$TEST_DIR"

# Verify tools are available
echo "=== Tool Verification ==="
which ruby && ruby --version
which standardrb && standardrb --version
which rubocop && rubocop --version
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
# Valid Ruby file (passes all linters)
cat > valid.rb << 'EOF'
# frozen_string_literal: true

class Greeter
  def greet(name)
    "Hello, #{name}!"
  end
end
EOF

# Ruby file with style issues (fixable)
cat > style_issues.rb << 'EOF'
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
cat > syntax_error.rb << 'EOF'
class Broken
  def unclosed
    puts "missing end"
EOF

# Create multiple files for batch testing
mkdir -p batch
cat > batch/file1.rb << 'EOF'
# frozen_string_literal: true

def file_one
  "one"
end
EOF

cat > batch/file2.rb << 'EOF'
def file_two()
  "two"
end
EOF

cat > batch/file3.rb << 'EOF'
# frozen_string_literal: true

class FileThree
  def run = "three"
end
EOF
SANDBOX
```

## Test Cases

### TC-001: StandardRB Available - Valid File

**Objective:** Verify that valid Ruby code passes linting when StandardRB is available.

**Steps:**
1. Lint the valid file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-lint lint valid.rb
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
   ace-test-e2e-sh "$TEST_DIR" cp style_issues.rb style_issues_copy.rb
   ```

2. Run lint with --fix on the copy
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-lint lint --fix style_issues_copy.rb
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   SANDBOX
   ```

3. Verify the file was modified by comparing to original
   ```bash
   ace-test-e2e-sh "$TEST_DIR" diff style_issues.rb style_issues_copy.rb
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ORIGINAL_PATH="$PATH"
   # Create a temporary bin directory without standardrb
   mkdir -p fake_bin
   for tool in ruby rubocop ace-lint; do
     ln -sf "$(which $tool)" fake_bin/
   done
   export PATH="$TEST_DIR/fake_bin:$PATH"

   # Verify standardrb is not available
   which standardrb 2>/dev/null && echo "ERROR: standardrb still found" || echo "OK: standardrb not in PATH"
   SANDBOX
   ```

2. Run linting (should fall back to RuboCop)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-lint lint valid.rb 2>&1
   ```

3. Restore PATH
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   export PATH="$ORIGINAL_PATH"
   SANDBOX
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
ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
# Find and temporarily rename the actual standardrb binary
STANDARDRB_PATH="$(mise which standardrb)"
mv "$STANDARDRB_PATH" "${STANDARDRB_PATH}.disabled"

# Run test...

# Restore after test
mv "${STANDARDRB_PATH}.disabled" "$STANDARDRB_PATH"
SANDBOX
```

---

### TC-004: Auto-fix Functionality

**Objective:** Verify that ace-lint can auto-fix style issues.

**Steps:**
1. Create a copy of the style issues file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" cp style_issues.rb style_issues_copy.rb
   ```

2. Run linting with auto-fix
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-lint lint --fix style_issues_copy.rb
   ```

3. Verify file was modified
   ```bash
   ace-test-e2e-sh "$TEST_DIR" diff style_issues.rb style_issues_copy.rb
   ```

4. Re-lint the fixed file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-lint lint style_issues_copy.rb
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
   ace-test-e2e-sh "$TEST_DIR" ace-lint lint batch/*.rb
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
