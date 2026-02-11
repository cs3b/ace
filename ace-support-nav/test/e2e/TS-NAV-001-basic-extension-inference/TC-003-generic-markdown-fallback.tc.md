---
tc-id: TC-003
title: Generic Markdown Fallback (.md)
---

## Objective

Verify that requesting a resource without extension falls back to generic .md extension when no protocol-specific extensions match.

## Steps

1. Resolve guide URI without extension and verify the generic .md fallback is used
   ```bash
   OUTPUT=$(ace-nav guide://quick-reference 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "quick-reference.md" && echo "PASS: Found quick-reference.md" || echo "FAIL: Output missing quick-reference.md"
   ```

2. Verify the resolved path is a valid file
   ```bash
   FILE_PATH=$(echo "$OUTPUT" | head -1)
   test -f "$FILE_PATH" && echo "PASS: Resolved path is a valid file" || echo "FAIL: Resolved path is not a valid file"
   ```

## Expected

- Exit code: 0
- Output contains path to `quick-reference.md`
- Inference tried protocol-specific extensions first, then found .md
