---
tc-id: TC-001
title: Valid File Lint and Report Generation
---

## Objective

Verify that linting a valid Ruby file exits 0, generates a well-structured report.json, and produces ok.md with correct format.

## Steps

1. Lint the valid file and capture output
   ```bash
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint lint valid.rb 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify report.json structure
   ```bash
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   REPORT_PATH="$REPORT_DIR/report.json"
   test -f "$REPORT_PATH" && echo "PASS: report.json exists" || echo "FAIL: report.json not found"
   echo "=== Top-level keys ==="
   cat "$REPORT_PATH" | jq 'keys'
   echo "=== Metadata keys ==="
   cat "$REPORT_PATH" | jq '.report_metadata | keys'
   echo "=== Summary keys ==="
   cat "$REPORT_PATH" | jq '.summary | keys'
   echo "=== Results keys ==="
   cat "$REPORT_PATH" | jq '.results | keys'
   ```

4. Verify ok.md exists with correct format
   ```bash
   test -f "$REPORT_DIR/ok.md" && echo "PASS: ok.md exists" || echo "FAIL: ok.md not found"
   grep -q "^# Lint: Passed Files" "$REPORT_DIR/ok.md" && echo "PASS: Header found" || echo "FAIL: Header missing"
   grep -q "^Generated:" "$REPORT_DIR/ok.md" && echo "PASS: Timestamp found" || echo "FAIL: Timestamp missing"
   grep -q "^- " "$REPORT_DIR/ok.md" && echo "PASS: File list found" || echo "FAIL: File list missing"
   ```

## Expected

- Exit code: 0
- report.json exists with top-level keys: `["report_metadata", "results", "summary"]`
- Metadata contains: `compact_id`, `generated_at`, `ace_lint_version`, `scan_options`
- Summary contains: `total_files`, `scanned`, `skipped`, `fixed`, `failed`, `passed`, `total_errors`, `total_warnings`
- Results contains: `fixed`, `failed`, `warnings_only`, `passed`, `skipped`
- ok.md exists with "# Lint: Passed Files" header, Generated timestamp, and file list
