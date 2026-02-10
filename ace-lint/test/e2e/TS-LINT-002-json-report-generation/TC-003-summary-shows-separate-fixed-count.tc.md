---
tc-id: TC-003
title: Summary Shows Separate Fixed Count
---

## Objective

Verify that auto-fixed files show as "fixed" in summary, not "passed".

## Steps

1. Run ace-lint with --fix on file with style issues
   ```bash
   cp style_issues.rb to_fix.rb
   OUTPUT=$(ace-lint lint --fix to_fix.rb 2>&1)
   echo "$OUTPUT"
   ```

2. Verify summary, report JSON, and fixed.md
   ```bash
   echo "$OUTPUT" | grep -E "✓.*fixed"
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   cat "$REPORT_DIR/report.json" | jq '.summary.fixed'
   test -f "$REPORT_DIR/fixed.md" && echo "fixed.md exists - PASS"
   ```

## Expected

- Summary output shows "X fixed" (not merged into "passed")
- Report JSON summary.fixed > 0
- File appears in results.fixed array, not results.passed
- fixed.md file exists in report directory
