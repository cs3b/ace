---
test-id: MT-LINT-006
title: Report Markdown Files
area: lint
package: ace-lint
priority: high
duration: ~10min
automation-candidate: true
requires:
  tools: [ace-lint]
  ruby: ">= 3.0"
last-verified: 2026-02-08
verified-by: claude-sonnet-4-5
---

# Report Markdown Files

## Objective

Verify that ace-lint generates correct markdown report files (ok.md, fixed.md, pending.md) with proper structure, headers, and content formatting.

## Prerequisites

- Ruby >= 3.0 installed
- ace-lint package available in PATH
- StandardRB or RuboCop available

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="lint"
SHORT_ID="mt006"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Set PROJECT_ROOT_PATH for sandbox isolation
export PROJECT_ROOT_PATH="$TEST_DIR"

# Initialize git repo (needed for project root detection)
git init --quiet .

echo "=== Tool Verification ==="
which ace-lint && ace-lint --version
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
# Valid Ruby file (will pass)
cat > valid.rb << 'EOF'
# frozen_string_literal: true

class Greeter
  def greet(name)
    "Hello, #{name}!"
  end
end
EOF

# Ruby file with style issues (will fail or be fixed)
cat > style_issues.rb << 'EOF'
class BadStyle
  def method_with_issues( arg1,arg2 )
    puts    "extra spaces"
  end
end
EOF

# Ruby file with syntax error (unfixable)
cat > syntax_error.rb << 'EOF'
class Broken
  def unclosed
    puts "missing end"
EOF
SANDBOX
```

## Test Cases

### TC-001: ok.md Generated for Passed Files

**Objective:** Verify ok.md is generated with correct format for passed files.

**Steps:**
1. Run ace-lint on valid file only
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint lint valid.rb 2>&1)
   echo "$OUTPUT"
   SANDBOX
   ```

2. Verify ok.md exists and has correct format
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   cat "$REPORT_DIR/ok.md"
   SANDBOX
   ```

3. Verify ok.md content structure
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   grep -q "^# Lint: Passed Files" "$REPORT_DIR/ok.md" && echo "Header - PASS"
   grep -q "^Generated:" "$REPORT_DIR/ok.md" && echo "Timestamp - PASS"
   grep -q "^Total:" "$REPORT_DIR/ok.md" && echo "Total count - PASS"
   grep -q "^- " "$REPORT_DIR/ok.md" && echo "File list - PASS"
   SANDBOX
   ```

**Expected:**
- ok.md exists when files pass
- Header is "# Lint: Passed Files"
- Contains Generated timestamp in ISO8601 format
- Contains Total count of files
- Contains file list with "- " prefix

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: fixed.md Generated Only When Files Fixed

**Objective:** Verify fixed.md is only generated when --fix is used and files are fixed.

**Steps:**
1. Run ace-lint WITHOUT --fix (should not generate fixed.md)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint lint style_issues.rb 2>&1)
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   test ! -f "$REPORT_DIR/fixed.md" && echo "No fixed.md without --fix - PASS"
   SANDBOX
   ```

2. Run ace-lint WITH --fix (should generate fixed.md)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   rm -rf .cache/ace-lint
   cp style_issues.rb fixable.rb
   OUTPUT=$(ace-lint lint --fix fixable.rb 2>&1)
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   test -f "$REPORT_DIR/fixed.md" && echo "fixed.md exists with --fix - PASS"
   SANDBOX
   ```

3. Verify fixed.md content structure
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat "$REPORT_DIR/fixed.md"
   grep -q "^# Lint: Auto-Fixed Files" "$REPORT_DIR/fixed.md" && echo "Header - PASS"
   grep -q "These files were automatically formatted/fixed:" "$REPORT_DIR/fixed.md" && echo "Description - PASS"
   SANDBOX
   ```

**Expected:**
- fixed.md does NOT exist when --fix is not used
- fixed.md exists when --fix is used and files were modified
- Header is "# Lint: Auto-Fixed Files"
- Contains description text about auto-fixed files

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: pending.md Checkbox Format

**Objective:** Verify pending.md has correct checkbox format for issues.

**Note:** This test uses `syntax_error.rb` (missing `end` keyword) which produces fatal-severity offenses and non-zero exit code regardless of which Ruby validator (StandardRB or RuboCop) is available. Convention/warning-only files like `style_issues.rb` exit 0 because ace-lint only fails on error/fatal severity.

**Steps:**
1. Run ace-lint on file with syntax error (unfixable, always fails)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint lint syntax_error.rb 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   cat "$REPORT_DIR/pending.md"
   SANDBOX
   ```

2. Verify exit code is non-zero for syntax errors
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit code for syntax error" || echo "FAIL: Expected non-zero exit code"
   SANDBOX
   ```

3. Verify pending.md header format
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   grep -q "^# Lint: Pending Issues" "$REPORT_DIR/pending.md" && echo "PASS: Main header found" || echo "FAIL: Main header not found"
   grep -q "^Total:.*issues in.*files" "$REPORT_DIR/pending.md" && echo "PASS: Total line found" || echo "FAIL: Total line not found"
   SANDBOX
   ```

4. Verify file section headers with issue counts
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   grep -E "^## .* \([0-9]+ issues?\)" "$REPORT_DIR/pending.md" && echo "PASS: File headers with counts found" || echo "FAIL: File headers not found"
   SANDBOX
   ```

5. Verify checkbox format for issues
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   grep -E "^- \[ \] " "$REPORT_DIR/pending.md" && echo "PASS: Checkbox format found" || echo "FAIL: Checkbox format not found"
   SANDBOX
   ```

**Expected:**
- pending.md has "# Lint: Pending Issues" header
- Contains "Total: N issues in M files" line
- Each file has "## filename (N issues)" header
- Each issue has "- [ ]" checkbox format

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

- [ ] TC-001: ok.md generated with correct format for passed files
- [ ] TC-002: fixed.md generated only when --fix is used
- [ ] TC-003: pending.md has correct checkbox format for issues

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Reports accumulate in .cache/ace-lint/ - manual cleanup may be needed
- The .cache/ directory is typically gitignored
