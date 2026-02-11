---
tc-id: TC-003
title: Exact Match Takes Precedence
---

## Objective

Verify that providing an explicit extension bypasses inference and matches the file exactly.

## Steps

1. Resolve with explicit full extension
   ```bash
   OUTPUT=$(ace-nav guide://coding-standards.guide.md 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "coding-standards.guide.md" && echo "PASS: Exact match found" || echo "FAIL: Exact match not found"
   ```

2. Verify the resolved path is a valid file
   ```bash
   FILE_PATH=$(echo "$OUTPUT" | head -1)
   test -f "$FILE_PATH" && echo "PASS: Resolved path is a valid file" || echo "FAIL: Resolved path is not a valid file"
   ```

## Expected

- Exit code: 0
- Output contains path to `coding-standards.guide.md`
- Exact match used (no inference needed)
