---
tc-id: TC-001
title: Cross-Protocol Extension Inference (wfi://)
---

## Objective

Verify extension inference works consistently across different protocols. The wfi:// protocol should infer .wf.md just like guide:// infers .g.md.

## Steps

1. Resolve workflow URI without extension
   ```bash
   OUTPUT=$(ace-nav wfi://setup 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "setup.wf.md" && echo "PASS: Found setup.wf.md" || echo "FAIL: Output missing setup.wf.md"
   ```

2. Verify the resolved path is a valid file
   ```bash
   FILE_PATH=$(echo "$OUTPUT" | head -1)
   test -f "$FILE_PATH" && echo "PASS: Resolved path is a valid file" || echo "FAIL: Resolved path is not a valid file"
   ```

## Expected

- Exit code: 0
- Output contains path to `setup.wf.md`
- wfi:// protocol inference works consistently with guide://
