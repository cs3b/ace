---
tc-id: TC-002
title: Report JSON Structure
---

## Objective

Verify the JSON report contains required structure.

## Steps

1. Run ace-lint and capture report path
   ```bash
   OUTPUT=$(ace-lint lint valid.rb 2>&1)
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   REPORT_PATH="$REPORT_DIR/report.json"
   ```

2. Parse the report and verify all structures
   ```bash
   echo "=== Top-level keys ==="
   cat "$REPORT_PATH" | jq 'keys'
   echo "=== Metadata ==="
   cat "$REPORT_PATH" | jq '.report_metadata | keys'
   cat "$REPORT_PATH" | jq '.report_metadata.compact_id'
   cat "$REPORT_PATH" | jq '.report_metadata.ace_lint_version'
   echo "=== Summary ==="
   cat "$REPORT_PATH" | jq '.summary | keys'
   echo "=== Results ==="
   cat "$REPORT_PATH" | jq '.results | keys'
   ```

## Expected

- Top-level keys: `["report_metadata", "results", "summary"]`
- Metadata contains: `compact_id`, `generated_at`, `ace_lint_version`, `scan_options`
- Summary contains: `total_files`, `scanned`, `skipped`, `fixed`, `failed`, `passed`, `total_errors`, `total_warnings`
- Results contains: `fixed`, `failed`, `warnings_only`, `passed`, `skipped`
