---
tc-id: TC-002
title: fixed.md Generated Only When Files Fixed
---

## Objective

Verify fixed.md is only generated when --fix is used and files are fixed.

## Steps

1. Run ace-lint WITHOUT --fix (should not generate fixed.md)
   ```bash
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint lint style_issues.rb 2>&1)
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   test ! -f "$REPORT_DIR/fixed.md" && echo "No fixed.md without --fix - PASS"
   ```

2. Run ace-lint WITH --fix (should generate fixed.md)
   ```bash
   rm -rf .cache/ace-lint
   cp style_issues.rb fixable.rb
   OUTPUT=$(ace-lint lint --fix fixable.rb 2>&1)
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   test -f "$REPORT_DIR/fixed.md" && echo "fixed.md exists with --fix - PASS"
   ```

3. Verify fixed.md content structure
   ```bash
   cat "$REPORT_DIR/fixed.md"
   grep -q "^# Lint: Auto-Fixed Files" "$REPORT_DIR/fixed.md" && echo "Header - PASS"
   grep -q "These files were automatically formatted/fixed:" "$REPORT_DIR/fixed.md" && echo "Description - PASS"
   ```

## Expected

- fixed.md does NOT exist when --fix is not used
- fixed.md exists when --fix is used and files were modified
- Header is "# Lint: Auto-Fixed Files"
- Contains description text about auto-fixed files
