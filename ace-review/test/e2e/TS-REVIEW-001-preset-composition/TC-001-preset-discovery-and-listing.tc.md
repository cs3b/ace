---
tc-id: TC-001
title: Preset Discovery and Listing
---

## Objective

Verify that ace-review discovers presets from both config and file-based sources, and list-presets shows all available presets.

## Steps

1. List available presets
   ```bash
   OUTPUT=$(ace-review --list-presets 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify base presets are discovered
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: list-presets succeeded" || echo "FAIL: Expected exit code 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "code-pr" && echo "PASS: code-pr preset discovered" || echo "FAIL: code-pr not found"
   echo "$OUTPUT" | grep -q "code" && echo "PASS: code preset discovered" || echo "FAIL: code not found"
   echo "$OUTPUT" | grep -q "level_3" && echo "PASS: level_3 preset discovered" || echo "FAIL: level_3 not found"
   ```

## Expected

- Exit code: 0
- code, code-pr, level_1, level_2, level_3, preset_a, preset_b, and broken presets are all discovered
- Presets listed in output
