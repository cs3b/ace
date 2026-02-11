---
tc-id: TC-003
title: Syntax Error Produces Pending Report
---

## Objective

Verify that a file with syntax errors produces a non-zero exit code and generates pending.md with correct checkbox format and section headers.

## Steps

1. Lint the syntax error file
   ```bash
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint lint syntax_error.rb 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify non-zero exit code
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit code ($EXIT_CODE)" || echo "FAIL: Expected non-zero, got $EXIT_CODE"
   ```

3. Verify pending.md exists with correct format
   ```bash
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   test -f "$REPORT_DIR/pending.md" && echo "PASS: pending.md exists" || echo "FAIL: pending.md not found"
   cat "$REPORT_DIR/pending.md"
   ```

4. Verify pending.md structure
   ```bash
   grep -q "^# Lint: Pending Issues" "$REPORT_DIR/pending.md" && echo "PASS: Header found" || echo "FAIL: Header missing"
   grep -E "^## .* \([0-9]+ issues?\)" "$REPORT_DIR/pending.md" && echo "PASS: File section headers found" || echo "FAIL: File section headers missing"
   grep -E "^- \[ \] " "$REPORT_DIR/pending.md" && echo "PASS: Checkbox format found" || echo "FAIL: Checkbox format missing"
   ```

## Expected

- Exit code: non-zero (syntax errors are fatal)
- pending.md exists with "# Lint: Pending Issues" header
- File section headers with issue counts: `## filename (N issues)`
- Each issue uses checkbox format: `- [ ]`
