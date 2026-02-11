---
tc-id: TC-001
title: Shorthand Extension Inference (.g.md)
---

## Objective

Verify that requesting a resource without extension finds the file with shorthand protocol extension (.g.md). This tests the DWIM behavior where `guide://markdown-style` resolves to `markdown-style.g.md`.

## Steps

1. Resolve guide URI without extension and verify the shorthand extension is found
   ```bash
   OUTPUT=$(ace-nav guide://markdown-style 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "markdown-style.g.md" && echo "PASS: Found markdown-style.g.md" || echo "FAIL: Output missing markdown-style.g.md"
   ```

2. Verify the resolved path is a valid file
   ```bash
   FILE_PATH=$(echo "$OUTPUT" | head -1)
   test -f "$FILE_PATH" && echo "PASS: Resolved path is a valid file" || echo "FAIL: Resolved path is not a valid file"
   ```

## Expected

- Exit code: 0
- Output contains path to `markdown-style.g.md`
- Resolved file path is valid and accessible
