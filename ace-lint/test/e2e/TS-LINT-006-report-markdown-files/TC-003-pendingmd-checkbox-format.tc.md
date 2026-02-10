---
tc-id: TC-003
title: pending.md Checkbox Format
---

## Objective

Verify pending.md has correct checkbox format for issues. This test uses `syntax_error.rb` (missing `end` keyword) which produces fatal-severity offenses and non-zero exit code regardless of which Ruby validator (StandardRB or RuboCop) is available.

## Steps

1. Run ace-lint on file with syntax error (unfixable, always fails)
   ```bash
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint lint syntax_error.rb 2>&1)
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

## Expected

- pending.md has "# Lint: Pending Issues" header
- Contains "Total: N issues in M files" line
- Each file has "## filename (N issues)" header
- Each issue has "- [ ]" checkbox format
