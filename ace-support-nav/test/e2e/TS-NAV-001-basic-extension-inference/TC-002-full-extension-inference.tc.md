---
tc-id: TC-002
title: Full Extension Inference (.guide.md)
---

## Objective

Verify that requesting a resource without extension finds the file with full protocol extension (.guide.md) when no shorthand match exists.

## Steps

1. Resolve guide URI without extension and verify the full extension is found
   ```bash
   OUTPUT=$(ace-nav guide://coding-standards 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "coding-standards.guide.md" && echo "PASS: Found coding-standards.guide.md" || echo "FAIL: Output missing coding-standards.guide.md"
   ```

2. Verify the resolved path is a valid file
   ```bash
   FILE_PATH=$(echo "$OUTPUT" | head -1)
   test -f "$FILE_PATH" && echo "PASS: Resolved path is a valid file" || echo "FAIL: Resolved path is not a valid file"
   ```

## Expected

- Exit code: 0
- Output contains path to `coding-standards.guide.md`
- Extension inference tried shorthand first, then found full extension
