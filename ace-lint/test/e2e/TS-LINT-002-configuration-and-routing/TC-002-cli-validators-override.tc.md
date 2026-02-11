---
tc-id: TC-002
title: CLI --validators Override
---

## Objective

Verify that `--validators` CLI flag overrides the config file, forcing all files through the specified validator regardless of group routing.

## Steps

1. Run with explicit --validators rubocop override
   ```bash
   OUTPUT=$(ace-lint lint --validators rubocop legacy/app.rb modern/app.rb 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify command completed successfully
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0 with rubocop override" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify both files were processed
   ```bash
   echo "$OUTPUT" | grep -qi "legacy" && echo "PASS: Legacy file processed" || echo "FAIL: Legacy file not found"
   echo "$OUTPUT" | grep -qi "modern" && echo "PASS: Modern file processed" || echo "FAIL: Modern file not found"
   ```

## Expected

- `--validators rubocop` overrides .ace/lint/ruby.yml config
- Both files processed with explicit validator (exit 0)
- Command completes successfully
