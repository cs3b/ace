---
tc-id: TC-002
title: Multi-Level Preset Composition and Model Inheritance
---

## Objective

Verify that three-level preset inheritance resolves correctly and that model settings are inherited from base presets via dry-run execution.

## Steps

1. Run ace-review with the level_3 preset (inherits level_2 -> level_1)
   ```bash
   OUTPUT=$(ace-review --preset level_3 --subject "test.rb" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify multi-level composition succeeds
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Multi-level composition succeeded" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   ```

3. Run ace-review with code-pr preset (inherits from code) to verify model inheritance
   ```bash
   OUTPUT2=$(ace-review --preset code-pr --subject "test.rb" --dry-run 2>&1)
   EXIT_CODE2=$?
   echo "$OUTPUT2"
   echo "Exit code: $EXIT_CODE2"
   [ "$EXIT_CODE2" -eq 0 ] && echo "PASS: code-pr dry-run succeeded" || echo "FAIL: Expected exit code 0, got $EXIT_CODE2"
   ```

## Expected

- Exit code: 0 for both commands
- level_3 preset resolves the entire chain (level_3 -> level_2 -> level_1)
- code-pr preset inherits model from code base preset
