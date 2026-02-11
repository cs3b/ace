---
tc-id: TC-002
title: Fix Mode Modifies File and Generates fixed.md
---

## Objective

Verify that `--fix` mode modifies files with style issues, reports fixed count > 0, and generates fixed.md with correct format.

## Steps

1. Create a copy of the style issues file and run fix mode
   ```bash
   rm -rf .cache/ace-lint
   cp style_issues.rb fixable.rb
   OUTPUT=$(ace-lint lint --fix fixable.rb 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify the file was modified
   ```bash
   diff style_issues.rb fixable.rb > /dev/null 2>&1 && echo "FAIL: File unchanged" || echo "PASS: File was modified by --fix"
   ```

3. Verify report shows fixed count > 0
   ```bash
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   FIXED_COUNT=$(cat "$REPORT_DIR/report.json" | jq '.summary.fixed')
   echo "Fixed count: $FIXED_COUNT"
   [ "$FIXED_COUNT" -gt 0 ] && echo "PASS: summary.fixed > 0" || echo "FAIL: summary.fixed is $FIXED_COUNT"
   ```

4. Verify fixed.md exists with correct format
   ```bash
   test -f "$REPORT_DIR/fixed.md" && echo "PASS: fixed.md exists" || echo "FAIL: fixed.md not found"
   grep -q "^# Lint: Auto-Fixed Files" "$REPORT_DIR/fixed.md" && echo "PASS: Header found" || echo "FAIL: Header missing"
   grep -qi "fixable.rb" "$REPORT_DIR/fixed.md" && echo "PASS: File listed in fixed.md" || echo "FAIL: File not in fixed.md"
   ```

5. Verify file appears in results.fixed
   ```bash
   cat "$REPORT_DIR/report.json" | jq '.results.fixed'
   cat "$REPORT_DIR/report.json" | jq '.results.fixed[] | .file_path' | grep -q "fixable.rb" && echo "PASS: File in results.fixed" || echo "FAIL: File not in results.fixed"
   ```

## Expected

- File content changed after --fix (diff shows differences)
- summary.fixed > 0 in report.json
- fixed.md exists with "# Lint: Auto-Fixed Files" header
- fixable.rb appears in fixed.md and results.fixed array
