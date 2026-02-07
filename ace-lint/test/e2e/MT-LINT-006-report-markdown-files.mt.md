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
last-verified: 2026-02-07
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

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="lint"
SHORT_ID="mt006"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize git repo (needed for project root detection)
git init --quiet .

echo "=== Tool Verification ==="
which ace-lint && ace-lint --version
echo "========================="
```

## Test Data

```bash
# Valid Ruby file (will pass)
cat > "$TEST_DIR/valid.rb" << 'EOF'
# frozen_string_literal: true

class Greeter
  def greet(name)
    "Hello, #{name}!"
  end
end
EOF

# Ruby file with style issues (will fail or be fixed)
cat > "$TEST_DIR/style_issues.rb" << 'EOF'
class BadStyle
  def method_with_issues( arg1,arg2 )
    puts    "extra spaces"
  end
end
EOF

# Ruby file with syntax error (unfixable)
cat > "$TEST_DIR/syntax_error.rb" << 'EOF'
class Broken
  def unclosed
    puts "missing end"
EOF
```

## Test Cases

### TC-001: ok.md Generated for Passed Files

**Objective:** Verify ok.md is generated with correct format for passed files.

**Steps:**
1. Run ace-lint on valid file only
   ```bash
   rm -rf "$TEST_DIR/.cache/ace-lint"
   OUTPUT=$(ace-lint lint "$TEST_DIR/valid.rb" 2>&1)
   echo "$OUTPUT"
   ```

2. Verify ok.md exists and has correct format
   ```bash
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   cat "$REPORT_DIR/ok.md"
   ```

3. Verify ok.md content structure
   ```bash
   grep -q "^# Lint: Passed Files" "$REPORT_DIR/ok.md" && echo "Header - PASS"
   grep -q "^Generated:" "$REPORT_DIR/ok.md" && echo "Timestamp - PASS"
   grep -q "^Total:" "$REPORT_DIR/ok.md" && echo "Total count - PASS"
   grep -q "^- " "$REPORT_DIR/ok.md" && echo "File list - PASS"
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
   rm -rf "$TEST_DIR/.cache/ace-lint"
   OUTPUT=$(ace-lint lint "$TEST_DIR/style_issues.rb" 2>&1)
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   test ! -f "$REPORT_DIR/fixed.md" && echo "No fixed.md without --fix - PASS"
   ```

2. Run ace-lint WITH --fix (should generate fixed.md)
   ```bash
   rm -rf "$TEST_DIR/.cache/ace-lint"
   cp "$TEST_DIR/style_issues.rb" "$TEST_DIR/fixable.rb"
   OUTPUT=$(ace-lint lint --fix "$TEST_DIR/fixable.rb" 2>&1)
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   test -f "$REPORT_DIR/fixed.md" && echo "fixed.md exists with --fix - PASS"
   ```

3. Verify fixed.md content structure
   ```bash
   cat "$REPORT_DIR/fixed.md"
   grep -q "^# Lint: Auto-Fixed Files" "$REPORT_DIR/fixed.md" && echo "Header - PASS"
   grep -q "These files were automatically formatted/fixed:" "$REPORT_DIR/fixed.md" && echo "Description - PASS"
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
   rm -rf "$TEST_DIR/.cache/ace-lint"
   OUTPUT=$(ace-lint lint "$TEST_DIR/syntax_error.rb" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   cat "$REPORT_DIR/pending.md"
   ```

2. Verify exit code is non-zero for syntax errors
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit code for syntax error" || echo "FAIL: Expected non-zero exit code"
   ```

3. Verify pending.md header format
   ```bash
   grep -q "^# Lint: Pending Issues" "$REPORT_DIR/pending.md" && echo "PASS: Main header found" || echo "FAIL: Main header not found"
   grep -q "^Total:.*issues in.*files" "$REPORT_DIR/pending.md" && echo "PASS: Total line found" || echo "FAIL: Total line not found"
   ```

4. Verify file section headers with issue counts
   ```bash
   grep -E "^## .* \([0-9]+ issues?\)" "$REPORT_DIR/pending.md" && echo "PASS: File headers with counts found" || echo "FAIL: File headers not found"
   ```

5. Verify checkbox format for issues
   ```bash
   grep -E "^- \[ \] " "$REPORT_DIR/pending.md" && echo "PASS: Checkbox format found" || echo "FAIL: Checkbox format not found"
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
