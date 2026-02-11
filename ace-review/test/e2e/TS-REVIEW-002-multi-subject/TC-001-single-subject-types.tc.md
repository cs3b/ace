---
tc-id: TC-001
title: Single Diff and Files Subject Processing
---

## Objective

Verify that ace-review correctly processes single diff and single files subjects via --dry-run.

## Steps

1. Run ace-review with a single diff subject
   ```bash
   OUTPUT_DIFF=$(ace-review --preset test --subject "diff:HEAD~1" --dry-run 2>&1)
   EXIT_DIFF=$?
   echo "Diff subject output:"
   echo "$OUTPUT_DIFF"
   echo "Exit code: $EXIT_DIFF"
   [ "$EXIT_DIFF" -eq 0 ] && echo "PASS: Single diff subject processed" || echo "FAIL: Expected exit code 0, got $EXIT_DIFF"
   ```

2. Run ace-review with a single files subject
   ```bash
   OUTPUT_FILES=$(ace-review --preset test --subject "files:*.md" --dry-run 2>&1)
   EXIT_FILES=$?
   echo "Files subject output:"
   echo "$OUTPUT_FILES"
   echo "Exit code: $EXIT_FILES"
   [ "$EXIT_FILES" -eq 0 ] && echo "PASS: Files subject processed" || echo "FAIL: Expected exit code 0, got $EXIT_FILES"
   ```

## Expected

- Exit code: 0 for both commands
- Single diff subject (diff:HEAD~1) is processed without error
- Single files subject (files:*.md) is processed without error
