---
tc-id: TC-001
title: Fallback Order Verification
---

## Objective

Verify the inference fallback priority: protocol_shorthand -> protocol_full -> generic_markdown -> bare. When multiple extension variants exist for the same base name, the shorthand (.g.md) should win.

## Steps

1. Resolve a resource that has multiple extension variants
   ```bash
   OUTPUT=$(ace-nav guide://multi-ext 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

2. Verify the shorthand extension (.g.md) was selected over full and generic
   ```bash
   echo "$OUTPUT" | grep -q "multi-ext.g.md" && echo "PASS: Shorthand .g.md selected (highest priority)" || echo "FAIL: Expected multi-ext.g.md"
   echo "$OUTPUT" | grep -c "multi-ext" | xargs -I{} sh -c '[ {} -le 2 ] && echo "PASS: DWIM returned focused result" || echo "FAIL: Too many results returned"'
   ```

## Expected

- Exit code: 0
- The `.g.md` version is returned (shorthand has highest priority)
- DWIM behavior: first match wins, not all matches
