---
tc-id: TC-004
title: Batch Mixed Results Categorization
---

## Objective

Verify that `--fix` on a mix of valid, fixable, and broken files correctly categorizes results into passed, fixed, and failed arrays, and generates all three markdown files.

## Steps

1. Prepare files and run batch lint with --fix
   ```bash
   rm -rf .cache/ace-lint
   cp style_issues.rb fixable.rb
   OUTPUT=$(ace-lint lint --fix valid.rb fixable.rb syntax_error.rb 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify report categorization
   ```bash
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   echo "=== Passed ==="
   cat "$REPORT_DIR/report.json" | jq '.results.passed | length'
   echo "=== Fixed ==="
   cat "$REPORT_DIR/report.json" | jq '.results.fixed | length'
   echo "=== Failed ==="
   cat "$REPORT_DIR/report.json" | jq '.results.failed | length'
   ```

3. Verify passed array contains valid.rb
   ```bash
   cat "$REPORT_DIR/report.json" | jq '.results.passed[] | .file_path' | grep -q "valid.rb" && echo "PASS: valid.rb in passed" || echo "FAIL: valid.rb not in passed"
   ```

4. Verify fixed array contains fixable.rb
   ```bash
   cat "$REPORT_DIR/report.json" | jq '.results.fixed[] | .file_path' | grep -q "fixable.rb" && echo "PASS: fixable.rb in fixed" || echo "FAIL: fixable.rb not in fixed"
   ```

5. Verify failed array contains syntax_error.rb
   ```bash
   cat "$REPORT_DIR/report.json" | jq '.results.failed[] | .file_path' | grep -q "syntax_error.rb" && echo "PASS: syntax_error.rb in failed" || echo "FAIL: syntax_error.rb not in failed"
   ```

6. Verify all three markdown files exist
   ```bash
   test -f "$REPORT_DIR/ok.md" && echo "PASS: ok.md exists" || echo "FAIL: ok.md missing"
   test -f "$REPORT_DIR/fixed.md" && echo "PASS: fixed.md exists" || echo "FAIL: fixed.md missing"
   test -f "$REPORT_DIR/pending.md" && echo "PASS: pending.md exists" || echo "FAIL: pending.md missing"
   ```

## Expected

- results.passed contains valid.rb (≥ 1 entry)
- results.fixed contains fixable.rb (≥ 1 entry)
- results.failed contains syntax_error.rb (≥ 1 entry)
- All three markdown files exist: ok.md, fixed.md, pending.md
