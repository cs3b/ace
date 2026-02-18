---
tc-id: TC-001
title: Group Routing with Config
---

## Objective

Verify that `.ace/lint/ruby.yml` is discovered from the filesystem and group patterns correctly route files to different validators. Both legacy/ and modern/ files should be processed successfully.

## Steps

1. Verify config file exists
   ```bash
   cat .ace/lint/ruby.yml && echo "PASS: Ruby config exists"
   ```

2. Lint both legacy and modern files
   ```bash
   OUTPUT=$(ace-lint lint legacy/app.rb modern/app.rb 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

3. Verify both files were processed
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -qiE "validated|passed|2 files" && echo "PASS: Files processed" || echo "FAIL: No validation summary in output"
   ```

## Expected

- .ace/lint/ruby.yml is discovered and used
- Both legacy/ and modern/ files processed successfully (exit 0)
- Output shows validation summary confirming files were processed
