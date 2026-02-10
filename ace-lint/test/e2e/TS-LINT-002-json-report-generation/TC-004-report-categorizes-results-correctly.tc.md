---
tc-id: TC-004
title: Report Categorizes Results Correctly (Fix Mode)
---

## Objective

Verify results are categorized into correct arrays with passed and fixed files.

## Steps

1. Lint multiple files with --fix (one clean, one with style issues to fix)
   ```bash
   rm -rf .cache/ace-lint
   cp style_issues.rb style_issues_copy.rb
   OUTPUT=$(ace-lint lint --fix valid.rb style_issues_copy.rb 2>&1)
   echo "$OUTPUT"
   ```

2. Check report categorization and markdown files
   ```bash
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   echo "Passed files:"
   cat "$REPORT_DIR/report.json" | jq '.results.passed | length'
   echo "Fixed files:"
   cat "$REPORT_DIR/report.json" | jq '.results.fixed | length'
   test -f "$REPORT_DIR/fixed.md" && echo "fixed.md exists - PASS"
   test -f "$REPORT_DIR/ok.md" && echo "ok.md exists - PASS"
   ```

## Expected

- `results.passed` contains valid.rb
- `results.fixed` contains style_issues_copy.rb
- Summary counts match array lengths
- fixed.md file exists for auto-fixed files
- ok.md file exists with passed files
